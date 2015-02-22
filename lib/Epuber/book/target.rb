# encoding: utf-8

require_relative '../dsl/tree_object'

require_relative '../vendor/version'
require_relative 'file_request'


module Epuber
  class Book
    class Target < DSL::TreeObject
      # @param [Target] parent
      # @param [String] name
      #
      def initialize(parent = nil, name)
        super(parent)

        @name      = name
        @is_ibooks = nil
        @files     = []
        @constants = {}
        @root_toc  = TocItem.new
      end

      def freeze
        super
        @files.freeze
        @files.each(&:freeze)
      end

      # @return [String] target name
      #
      attr_reader :name

      # @return [Array<self>] list of sub targets
      #
      alias_method :sub_targets, :sub_items

      # @return [Epuber::Book::TocItem]
      #
      attr_reader :root_toc


      # Create new sub_target with name
      #
      # @param [String] name
      #
      # @return [Target] new created sub target
      #
      def sub_target(name)
        child = create_child_item(name)

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
        all_files = ((parent && parent.files) || []) + @files

        unless @attributes_values[:cover_image].nil?
          all_files << @attributes_values[:cover_image]
        end

        all_files
      end

      # Returns all constants
      # @return [Hash<String, Object>]
      #
      def constants
        ((parent && parent.constants) || {}).merge(@constants)
      end

      #----------------------- DSL items ---------------------------



      # @return [String] version of result epub
      #
      attribute :epub_version,
                required:     true,
                inherited:    true,
                types:        [Version],
                auto_convert: { [String, Fixnum, Float] => Version },
                default_value: 3.0

      # @return [String] isbn of epub
      #
      attribute :isbn,
                inherited: true

      # @return [String] target will use custom font (for iBooks only)
      #
      attribute :custom_fonts,
                types:     [TrueClass, FalseClass],
                inherited: true

      # @return [Bool] hint for compiler to add some iBooks related stuff
      #
      attribute :is_ibooks,
                types:     [TrueClass, FalseClass],
                inherited: true

      attribute :cover_image,
                types:        [FileRequest],
                inherited:    true,
                auto_convert: { [String] => ->(value) { FileRequest.new(value, group: :image, properties: [:cover_image]) } }


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

        @files << file unless @files.include?(file)

        file
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
      def add_const(key, value)
        @constants[key] = value
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
    end
  end
end
