# encoding: utf-8

module Epuber
  class Checker
    require_relative 'checker/text_checker'


    # Type of checker, valid values are:
    #    :result_text_xhtml_string     just before writing result xhtml to build folder
    #
    # @return [Symbol]
    #
    attr_reader :type

    # In which configuration should this checker run, valid values:
    #     :all           every time
    #     :release       just before creating final version
    #
    # @return [Symbol]
    #
    attr_reader :configuration

    # @return [Proc]
    #
    attr_reader :block

    # @param type [Symbol] type of checker, see #type
    # @param configuration [Symbol] configuration for this checker, see #configuration
    #
    def initialize(type, configuration, &block)
      @type = type
      @configuration = configuration
      @block = block
    end


    # @return [Array<Problem>]
    #
    def call(*args)
      raise NotImplementedError, 'You should override this method'
    end


    # ------------------------------------------------------------------ #
    # @group Registration

    # @return [Hash<Symbol, Checker>]
    #
    def self.registered_checkers
      @@registered_checkers ||= {}
    end

    # @param type [Symbol]
    # @param klass [Class]
    #
    def self.register(type, klass: self)
      self.registered_checkers[type] = klass
    end

    def self.checker_class_for_type(type)
      checker_class = self.registered_checkers[type]
      raise "Checker class not found for type: #{type.inspect}" if checker_class.nil?
      checker_class
    end

    TextChecker.register(:result_text_xhtml_string)
  end
end
