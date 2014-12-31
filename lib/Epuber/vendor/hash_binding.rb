# encoding: utf-8

module Epuber
  class HashBinding
    def initialize(vars = {})
      @vars = vars
    end

    def method_missing(name)
      raise "Not found value for key #{name}" unless @vars.key?(name)
      @vars[name]
    end

    # rubocop:disable Style/AccessorMethodName

    def get_binding
      binding
    end

    # rubocop:enable Style/AccessorMethodName
  end
end
