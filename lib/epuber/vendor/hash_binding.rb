# frozen_string_literal: true

module Epuber
  class HashBinding
    # @param [Hash] vars
    #
    def initialize(vars = {})
      @vars = vars
    end

    # @param [String] name
    #
    def method_missing(name)
      raise NameError, "Not found value for key #{name}" unless @vars.key?(name)

      @vars[name]
    end

    # rubocop:disable Style/AccessorMethodName

    def get_binding
      binding
    end

    # rubocop:enable Style/AccessorMethodName
  end
end
