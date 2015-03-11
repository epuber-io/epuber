# encoding: utf-8

module Epuber
  class Transformer
    require_relative 'transformer/text_transformer'

    # Type of source value for this transformer, valid values are:
    #    :source_writable              this will make transformations on source file and writes them back
    #    :result_text_xhtml_string     just before writing result xhtml to build folder
    #
    # @return [Symbol]
    #
    attr_reader :source_type

    MAP_SOURCE_TYPE__CLASS = {
      :result_text_xhtml_string => TextTransformer
    }.freeze



    # When should this checker run, valid values:
    #     :always            every time
    #     :before_release    just before creating final version
    #
    # @return [Symbol]
    #
    attr_reader :run_when

    RUN_WHEN_VALUES = [:always, :before_release]



    # @return [Proc]
    #
    attr_reader :block



    # @param type [Symbol] type of checker, see #type
    # @param run_when [Symbol] configuration for this checker, see #configuration
    #
    def initialize(type, run_when, &block)
      @source_type = type
      @block = block

      raise "Unknown run_when #{run_when.inspect} for transformers, valid are: #{RUN_WHEN_VALUES}" unless RUN_WHEN_VALUES.include?(run_when)
      @run_when = run_when
    end


    # @return [Object] actual type depends on source_type and input value
    #
    def call(*args)
      raise NotImplementedError, 'You should override this method'
    end


    # ------------------------------------------------------------------ #
    # @group Registration

    # @param type [Symbol]
    #
    # @return [Class]
    #
    def self.class_for_source_type(type)
      transformer_class = MAP_SOURCE_TYPE__CLASS[type]
      raise "Transformer class not found for type: #{type.inspect}" if transformer_class.nil?
      transformer_class
    end
  end
end
