
module Epuber
  class CheckerTransformerBase

    # Type of source value for this checker, valid values are:
    #    :result_text_xhtml_string     just before writing result xhtml to build folder
    #
    # @return [Symbol]
    #
    attr_reader :source_type

    # List of options/flags passed in from plugin instance
    #
    # @return [Array<Symbol>]
    #
    attr_reader :options

    # @return [Proc]
    #
    attr_reader :block


    # @param [Symbol] type type of checker, see #type
    # @param [Array<Symbol>] options list of other arguments, usually flags
    #
    def initialize(type, *options, &block)
      @source_type = type
      @block = block

      valid_options_inst = valid_options
      options.each do |opt|
        raise "Unknown option #{opt.inspect}" unless valid_options_inst.include?(opt)
      end
      @options = options
    end

    # @return [Array<Symbol>]
    #
    def valid_options
      [:run_only_before_release, :interactive]
    end



    def call(*args)
      raise NotImplementedError, 'You should override this method'
    end



    # ------------------------------------------------------------------ #
    # @group Registration

    # @return [Hash<Symbol, Class>]
    #
    def self.map_source_type__class
      {}
    end


    # @param type [Symbol]
    #
    # @return [Class]
    #
    def self.class_for_source_type(type)
      checker_class = self.map_source_type__class[type]
      raise "#{self} class not found for type: #{type.inspect}" if checker_class.nil?
      checker_class
    end
  end
end
