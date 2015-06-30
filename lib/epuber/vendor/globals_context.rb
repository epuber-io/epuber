
module Epuber
  class GlobalsContext
    attr_accessor :catch_variables

    def initialize
      @catch_variables = []
    end

    def catch
      before = global_variables

      yield

      @catch_variables += (global_variables - before)
    end

    def clear_all
      @catch_variables.each do |name|
        eval("#{name} = nil")
      end
    end
  end
end