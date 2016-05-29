# encoding: utf-8


module Epuber
  class Compiler
    module FileTypes
      require_relative 'source_file'

      class StaticFile < SourceFile
        # @param [Compiler::CompilationContext] _compilation_context
        #
        def process(_compilation_context)
          default_file_copy
        end
      end
    end
  end
end
