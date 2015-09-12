# encoding: utf-8


module Epuber
  class Compiler
    module FileTypes
      require_relative 'source_file'

      class StaticFile < SourceFile
        def process(opts = {})
          self.class.file_copy(source_path, destination_path)
        end
      end
    end
  end
end
