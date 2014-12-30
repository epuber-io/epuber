require_relative 'dsl/object'

require_relative 'book/contributor'
require_relative 'book/toc_item'
require_relative 'book/target'

require_relative 'vendor/version'

module Epuber
  module Book
    class StandardError < ::StandardError; end

    class Book < DSL::Object

      def initialize
        super

        @default_target   = Target.new(:default)
        @root_toc         = TocItem.new

        yield self if block_given?
      end

      def validate
        super

        @default_target.validate
      end

      attr_reader :default_target


      private

      # Defines setter and getter for default target attribute
      #
      # @param [Symbol] sym  attribute name
      #
      # @return [Void]
      #
      def self.default_target_attribute(sym, readonly: false)

        # getter
        define_method(sym) do
          @default_target.send(sym)
        end

        unless readonly
          # setter
          setter_method = sym.to_s + '='
          define_method(setter_method) do |newValue|
            @default_target.send(setter_method, newValue)
          end
        end
      end


      #-------------- Targets ----------------------------------
      public

      # All targets
      #
      # @return [Array<Target>]
      #
      def targets
        if @default_target.sub_targets.length == 0
          [@default_target]
        else
          @default_target.sub_targets
        end
      end

      # Defines new target
      #
      # @return [Target] result target
      #
      def target(name)
        @default_target.sub_target(name) do |target|
          yield target if block_given?
        end
      end


      #-------------- TOC --------------------------------------

      # @return [TocItem]
      #
      attr_reader :root_toc

      def toc(&block)
        @root_toc.create_child_items(&block)
      end

      #------------- DSL attributes ------------------------------------------------------------------------------------

      # @return [String] title of book
      #
      attribute :title,
                required: true

      # @return [String] subtitle of book
      #
      attribute :subtitle

      # @return [Array<Contributor>] authors of book
      #
      attribute :authors,
                types:        [Contributor, NormalContributor],
                container:    Array,
                required:     true,
                singularize:  true,
                auto_convert: { [String, Hash] => lambda { |value| Contributor.from_ruby(value, 'aut') } }


      # @return [String] publisher name
      #
      attribute :publisher

      # @return [String] language of this book
      #
      attribute :language

      # @return [Bool] book is for iBooks
      #
      default_target_attribute :is_ibooks

      # @return [String] isbn of this book
      #
      default_target_attribute :isbn

      # @return [String|Fixnum] epub version
      #
      default_target_attribute :epub_version

      # @return [Bool] book uses custom fonts (used only for iBooks)
      #
      default_target_attribute :custom_fonts

      # @return [String] path or name of cover image
      #
      default_target_attribute :cover_image

      # @return [String] isbn of printed book
      #
      attribute :print_isbn

      # @return [Date] date of book was published
      #
      attribute :published,
                types:        [Date],
                auto_convert: { String => Date }


      # @return [Version] book version
      # @note Is used only for ibooks versions
      #
      attribute :version,
                inherited:    true,
                types:        [Version],
                auto_convert: { [String, Fixnum, Float] => Version }

      # @return [String] build version of book
      #
      attribute :build_version,
                types:        [Version],
                auto_convert: { [String, Fixnum, Float] => Version }

      # @return [String] base name for output epub file
      #
      attribute :output_base_name,
                inherited: true


      # Add file to book, see {Target#add_file} to more details
      #
      def add_file(*args)
        @default_target.add_file(*args)
      end

      # Add files to book, see Target#add_files to more details
      #
      def add_files(*file_paths)
        @default_target.add_files(*file_paths)
      end


      # Add constant to target, constants can be used within text files
      #
      def add_const(*args)
        @default_target.add_const(*args)
      end





      # --------------------------------------------------------------------- #
      # @!group Other methods

      # Finds target with name or nil when not found
      #
      # @param target_name [Symbol, String, Epuber::Book::Target]
      #
      # @return [Epuber::Book::Target, nil]
      #
      def target_named(target_name)
        if target_name.is_a?(Epuber::Book::Target)
          return target_name
        end

        targets.find { |target|
          target.name == target_name || target.name.to_s == target_name.to_s
        }
      end

      # TODO footnotes customization
      # TODO custom metadata
      # TODO custom user informations (just global available Hash<String, Any>)
      # TODO url (book url) // http://melvil.cz/kniha-prace-na-dalku
    end
  end
end
