# encoding: utf-8

require 'unicode_normalize'


module Epuber
  class Compiler
    module FileFinders
      require_relative 'abstract'

      class Normal < Abstract
        def __core_find_files_from_pattern(pattern)
          Dir.glob(pattern)
        end
      end
    end
  end
end
