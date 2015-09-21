# encoding: utf-8

require 'stylus'


module Epuber
  class Compiler
    module FileTypes
      require_relative 'source_file'

      class StylusFile < SourceFile
        # @param [Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          write_compiled(Stylus.compile(File.new(abs_source_path)))
        end
      end
    end
  end
end
