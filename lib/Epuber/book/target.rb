# encoding: utf-8

require_relative '../dsl/tree_object'

require_relative '../vendor/version'
require_relative 'file'


module Epuber
  module Book
    class Target < DSL::TreeObject
      # @param [Target] parent
      # @param [String] name
      #
      def initialize(parent = nil, name)
        super(parent)

        @name      = name
        @is_ibooks = nil
        @files     = []
        @all_files = []
        @constants = {}
        @root_toc  = TocItem.new
      end

      # @return [String] target name
      #
      attr_reader :name

      # @return [Array<self.class>] list of sub targets
      #
      alias_method :sub_targets, :child_items


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
      alias_method :is_ibooks?, :ibooks?


      # Returns all files
      # @return [Array<Epuber::Book::File>]
      #
      def files
        # parent files plus our files
        ((parent && parent.files) || []) + @files
      end

      # @return [Array<Epuber::Book::File>]
      #
      def all_files
        ((parent && parent.all_files) || []) + @all_files
      end

      def add_to_all_files(file)
        @all_files << file
      end

      # @param file [Epuber::Book::File]
      # @param files [Array<Epuber::Book::Files>]
      #
      def replace_file_with_files(file, files)
        if @files.include?(file) || @all_files.include?(file)
          index = @files.index(file)
          unless index.nil?
            @files.delete_at(index)
            @files.insert(index, *files)
          end

          index = @all_files.index(file)
          unless index.nil?
            @all_files.delete_at(index)
            @all_files.insert(index, *files)
          end
        elsif !parent.nil?
          parent.replace_file_with_files(file, files)
        end
      end

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
                types:        [Epuber::Book::File],
                inherited:    true,
                auto_convert: { [String] => ->(value) { File.new(value, group: :image, properties: ['cover-image']) } }


      # @param file_path [String | Epuber::Book::File]
      # @param group [Symbol]
      #
      # @return [Epuber::Book::File] created file
      #
      def add_file(file_path, group: nil)
        file = if file_path.is_a?(Epuber::Book::File)
                 file_path
               else
                 Epuber::Book::File.new(file_path, group: group)
               end

        @files << file unless @files.include?(file)
        @all_files << file unless @all_files.include?(file)

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

      # TODO: store url
    end
  end
end
