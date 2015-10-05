# encoding: utf-8

module Epuber
  class Compiler
    module FileFinders
      require_relative 'abstract'

      class Normal < Abstract
        def __core_find_files_from_pattern(pattern)
          Dir.glob(pattern)
        end

        def __core_file?(path)
          File.file?(path)
        end
      end
    end
  end
end
