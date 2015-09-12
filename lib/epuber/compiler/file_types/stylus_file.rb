# encoding: utf-8


module Epuber
  class Compiler
    module FileTypes
      require_relative 'source_file'

      class StylusFile < SourceFile
        def process(opts = {})
          raise 'Implement'
        end
      end
    end
  end
end
