# encoding: utf-8


module Epuber
  class Compiler
    module FileTypes
      require_relative 'source_file'

      class StaticFile < SourceFile
        # @param [Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          self.class.file_copy(abs_source_path, final_destination_path)
        end
      end
    end
  end
end
