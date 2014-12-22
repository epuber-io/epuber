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
      end

      # @return [String] target name
      #
      attr_reader :name

      # @return [Array<self.class>] list of sub targets
      #
      alias_method :sub_targets, :child_items


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
      def is_ibooks?
        if self.is_ibooks.nil?
          name.include?('ibooks')
        else
          self.is_ibooks
        end
      end

      # Returns all files
      # @return [Array<Epuber::Book::File>]
      #
      def files
        # parent files plus our files
        ((self.parent && self.parent.files) || []) + @files
      end

      # @return [Array<Epuber::Book::File>]
      #
      def all_files
        ((self.parent && self.parent.all_files) || []) + @all_files
      end

      def add_to_all_files(file)
        @all_files << file
      end

      #----------------------- DSL items ---------------------------



      # @return [String] version of result epub
      #
      attribute :epub_version,
                required:     true,
                inherited:    true,
                types:        [Version],
                auto_convert: { [String, Fixnum, Float] => Version }

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
                auto_convert: { [String] => Epuber::Book::File }


      # @param file_path [String | Epuber::Book::File]
      #
      def add_file(file_path)
        file = if file_path.is_a?(Epuber::Book::File)
                 file_path
               else
                 Epuber::Book::File.new(file_path)
               end

        @files << file unless @files.include?(file)
        @all_files << file unless @all_files.include?(file)
      end



      # TODO store url
    end
  end
end
