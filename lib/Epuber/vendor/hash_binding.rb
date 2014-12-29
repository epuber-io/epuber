module Epuber
  class HashBinding
    def initialize(vars = {})
      @vars = vars
    end
    def method_missing(name)
      raise "Not found value for key #{name}" unless @vars.has_key?(name)
      @vars[name]
    end
    def get_binding
      binding
    end
  end
end
