# frozen_string_literal: true

require_relative '../vendor/version'
require_relative '../vendor/size'
require_relative '../dsl/tree_object'

module Epuber
  class Book
    require_relative 'file_request'

    class Target < DSL::TreeObject
      # @param [Target] parent  reference to parent target
      # @param [String] name  name of this target
      #
      def initialize(name, parent: nil)
        super(parent)

        @name      = name
        @is_ibooks = nil
        @book      = nil
        @files     = []
        @constants = {}
        @root_toc  = TocItem.new

        @default_styles = []
        @default_scripts = []
        @plugins = []
      end

      def freeze
        super
        @files.freeze
        @files.each(&:freeze)

        @default_styles.freeze
        @default_styles.each(&:freeze)

        @default_scripts.freeze
        @default_scripts.each(&:freeze)

        @plugins.freeze
        @plugins.each(&:freeze)

        @root_toc.freeze
        @constants.freeze
      end

      # @return [String, Symbol] target name
      #
      attr_reader :name

      # @return [Array<self>] list of sub targets
      #
      alias sub_targets sub_items

      # @return [Epuber::Book::TocItem]
      #
      attr_reader :root_toc

      # @return [Epuber::Book] reference to book
      #
      attr_writer :book

      # @return [Epuber::Book] reference to book
      #
      def book
        @book || parent&.book
      end

      # Create new sub_target with name
      #
      # @param [String] name
      #
      # @return [Target] new created sub target
      #
      def sub_target(name)
        child = create_child_item(name)
        child.book = book

        yield child if block_given?

        child
      end

      # Create new sub_target with name
      #
      # @param [String] name
      #
      # @return [Target] new created sub target
      #
      def sub_abstract_target(name)
        child = create_child_item(name)
        child.book = book
        child.is_abstract = true

        yield child if block_given?

        child
      end

      #------------- other methods ---------------------------------

      # @return [Bool]
      #
      def ibooks?
        if is_ibooks.nil?
          name.to_s.include?('ibooks')
        else
          is_ibooks
        end
      end

      # Returns all files
      # @return [Array<Epuber::Book::FileRequest>]
      #
      def files
        # parent files plus our files
        all_files = ((parent && parent.files) || []) + @files + @default_styles + @default_scripts

        all_files << @attributes_values[:cover_image] unless @attributes_values[:cover_image].nil?

        all_files
      end

      # Returns all constants
      # @return [Hash<String, Object>]
      #
      def constants
        (parent&.constants || {}).merge(@constants)
      end

      # @return [Array<Epuber::Book::FileRequest>]
      #
      def default_styles
        ((parent && parent.default_styles) || []) + @default_styles
      end

      # @return [Array<Epuber::Book::FileRequest>]
      #
      def default_scripts
        ((parent && parent.default_scripts) || []) + @default_scripts
      end

      # @return [Array<String>]
      #
      def plugins
        ((parent && parent.plugins) || []) + @plugins
      end

      #----------------------- DSL items ---------------------------



      # @return [String] version of result epub
      #
      attribute :epub_version,
                required: true,
                inherited: true,
                auto_convert: { [String, Integer, Float] => Version },
                default_value: 3.0

      # @return [String] isbn of epub
      #
      attribute :isbn,
                inherited: true

      # @return [String] book identifier used in OPF file
      #
      attribute :identifier,
                inherited: true

      # @return [String] target will use custom font (for iBooks only)
      #
      attribute :custom_fonts,
                types: [TrueClass, FalseClass],
                inherited: true

      # @return [Bool] hint for compiler to add some iBooks related stuff
      #
      attribute :is_ibooks,
                types: [TrueClass, FalseClass],
                inherited: true

      # @return [Bool] whether the target uses fixed layout
      #
      attribute :fixed_layout,
                types: [TrueClass, FalseClass],
                inherited: true

      # @return [FileRequest] file request to cover image
      #
      attribute :cover_image,
                types: [FileRequest],
                inherited: true,
                auto_convert: { [String] => lambda { |value|
                                              FileRequest.new(value, group: :image, properties: [:cover_image])
                                            } }

      # @return [Size] size of view port, mainly this is used for fixed layout
      #
      attribute :default_viewport,
                types: [Size],
                inherited: true

      # @return [Bool] whether the target should create mobi
      #
      attribute :create_mobi,
                types: [TrueClass, FalseClass],
                inherited: true

      # @return [Bool] allows to create abstract targets that are only used as template for other targets
      #
      attribute :is_abstract,
                types: [TrueClass, FalseClass],
                inherited: false


      # @param file_path [String | Epuber::Book::File]
      # @param group [Symbol]
      #
      # @return [Epuber::Book::File] created file
      #
      def add_file(file_path, group: nil)
        file = if file_path.is_a?(FileRequest)
                 file_path
               else
                 FileRequest.new(file_path, group: group)
               end


        old_file = @files.find { |f| f == file }

        if old_file.nil?
          @files << file
          file
        else
          old_file
        end
      end

      # @param file_paths [Array<String>]
      #
      # @return [void]
      #
      def add_files(*file_paths)
        file_paths.each do |file_path|
          file_obj          = add_file(file_path)
          file_obj.only_one = false
        end
      end

      # @param key [String]
      # @param value [String]
      #
      # @return [void]
      #
      def add_const(key, value = nil)
        if key.is_a?(Hash) && value.nil?
          @constants.merge!(key)
        else
          @constants[key] = value
        end
      end

      # @param file_paths [Array<String>]
      #
      # @return [void]
      #
      def add_default_style(*file_paths)
        file_paths.map do |file_path|
          file_obj          = add_file(file_path, group: :style)
          file_obj.only_one = true

          @default_styles << file_obj unless @default_styles.include?(file_obj)
        end
      end

      # Add default styles to default target, default styles will be automatically added to xhtml document
      #
      # Only difference with #add_default_style is it adds multiple files with one pattern
      # @param file_paths [Array<String>]
      #
      # @return [void]
      #
      def add_default_styles(*file_paths)
        file_paths.map do |file_path|
          file_obj          = add_file(file_path, group: :style)
          file_obj.only_one = false

          @default_styles << file_obj unless @default_styles.include?(file_obj)
        end
      end

      # @param file_paths [Array<String>]
      #
      # @return [void]
      #
      def add_default_script(*file_paths)
        file_paths.map do |file_path|
          file_obj          = add_file(file_path, group: :script)
          file_obj.only_one = true

          @default_scripts << file_obj unless @default_scripts.include?(file_obj)
        end
      end

      # Add default scripts to target, default scripts will be automatically added to xhtml document
      #
      # Only difference with #add_default_script is it adds multiple files with one pattern
      # @param file_paths [Array<String>]
      #
      # @return [void]
      #
      def add_default_scripts(*file_paths)
        file_paths.map do |file_path|
          file_obj          = add_file(file_path, group: :script)
          file_obj.only_one = false

          @default_scripts << file_obj unless @default_scripts.include?(file_obj)
        end
      end

      # @yield [toc_item, target]
      # @yieldparam toc_item [TocItem] root toc item
      # @yieldparam target [self] current target
      #
      # @return nil
      #
      def toc
        yield(@root_toc, self) if block_given?
      end

      # @param path [String] use some file/module/package
      #
      # @return [nil]
      #
      def use(path)
        @plugins << path
      end
    end
  end
end
