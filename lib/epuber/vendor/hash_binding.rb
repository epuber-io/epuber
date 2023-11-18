# frozen_string_literal: true

module Epuber
  class HashBinding
    # @param [Hash] vars
    #
    def initialize(vars = {})
      @vars = vars
    end

    # @return [Boolean]
    #
    def respond_to_missing?(name, _include_private = false)
      @vars.key?(name) || super
    end

    # @param [String] name
    #
    def method_missing(name)
      raise NameError, "Not found value for key #{name}" unless @vars.key?(name)

      @vars[name]
    end

    # rubocop:disable Naming/AccessorMethodName

    def get_binding
      binding
    end

    # rubocop:enable Naming/AccessorMethodName
  end
end
