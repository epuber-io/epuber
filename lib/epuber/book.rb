# frozen_string_literal: true

require_relative 'dsl/object'

module Epuber
  class Book < DSL::Object
    require_relative 'book/contributor'
    require_relative 'book/target'
    require_relative 'book/toc_item'
    require_relative 'book/file_request'

    class StandardError < ::StandardError; end

    def initialize
      super

      @default_target = Target.new(nil)
      @toc_blocks     = []

      yield self if block_given?
    end

    # @return nil
    #
    def finish_toc
      @toc_blocks.each do |block|
        flat_all_targets.each do |target|
          target.toc(&block)
        end
      end
    end

    # @return nil
    #
    def validate
      super
      @default_target.validate
    end

    # @return nil
    #
    def freeze
      super
      @default_target.freeze
    end

    # @return [Epuber::Book::Target]
    #
    attr_reader :default_target


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

      return if readonly

      # setter
      setter_method = "#{sym}="
      define_method(setter_method) do |newValue|
        @default_target.send(setter_method, newValue)
      end
    end


    #-------------- Targets ----------------------------------

    # All targets
    #
    # @return [Array<Target>]
    #
    def all_targets
      if @default_target.sub_targets.empty?
        [@default_target]
      else
        @default_target.sub_targets
      end
    end

    def flat_all_targets
      if @default_target.sub_targets.empty?
        [@default_target]
      else
        @default_target.flat_sub_items
      end
    end

    def buildable_targets
      flat_all_targets.reject(&:is_abstract)
    end

    # Defines new target
    #
    # @param [String, Symbol] name
    #
    # @return [Target] result target
    #
    def target(name)
      @default_target.sub_target(name) do |target|
        target.book = self
        yield target if block_given?
      end
    end

    def abstract_target(name)
      @default_target.sub_abstract_target(name) do |target|
        target.book = self
        yield target if block_given?
      end
    end

    # Defines several new targets with same configuration
    #
    # @param [Array<String, Symbol>] names
    #
    # @return [Array<Target>] result target
    #
    def targets(*names, &block)
      if names.empty?
        UI.warning('Book#targets to get all targets is deprecated, use #all_targets instead',
                   location: caller_locations.first)
        return all_targets
      end

      names.map { |name| target(name, &block) }
    end


    #-------------- TOC --------------------------------------

    # @return nil
    #
    def toc(&block)
      @toc_blocks << block
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
              types: [Contributor, NormalContributor],
              container: Array,
              required: true,
              singularize: true,
              auto_convert: { [String, Hash] => ->(value) { Contributor.from_obj(value, 'aut') } }


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

    # @return [Bool] whether the book uses fixed layout
    #
    default_target_attribute :fixed_layout

    # @return [String] path or name of cover image
    #
    default_target_attribute :cover_image

    # @return [Size] default view port size
    #
    default_target_attribute :default_viewport

    # @return [Bool] whether the target should create mobi
    #
    default_target_attribute :create_mobi

    # @return [String] book identifier used in OPF file
    #
    default_target_attribute :identifier


    # @return [String] isbn of printed book
    #
    attribute :print_isbn

    # @return [Date] date of book was published
    #
    attribute :published,
              types: [Date],
              auto_convert: { String => Date }


    # @return [Version] book version
    # @note Is used only for ibooks versions
    #
    attribute :version,
              inherited: true,
              types: [Version],
              auto_convert: { [String, Integer, Float] => Version }

    # @return [String] build version of book
    #
    attribute :build_version,
              types: [Version],
              auto_convert: { [String, Integer, Float] => Version }

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

    # Add default styles to default target, default styles will be automatically added to xhtml document
    #
    def add_default_style(*file_paths)
      @default_target.add_default_style(*file_paths)
    end

    # Add default styles to default target, default styles will be automatically added to xhtml document
    #
    def add_default_styles(*file_paths)
      @default_target.add_default_styles(*file_paths)
    end

    # Add default script to default target, default scripts will be automatically added to xhtml document
    #
    def add_default_script(*file_paths)
      @default_target.add_default_script(*file_paths)
    end

    # Add default scripts to default target, default scripts will be automatically added to xhtml document
    #
    def add_default_scripts(*file_paths)
      @default_target.add_default_scripts(*file_paths)
    end

    # Method to add plugin, that should be used while building book
    #
    def use(path)
      @default_target.use(path)
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
      return target_name if target_name.is_a?(Epuber::Book::Target)

      flat_all_targets.find do |target|
        target.name == target_name || target.name.to_s == target_name.to_s
      end
    end

    # TODO: footnotes customization
    # TODO: custom metadata
  end
end
