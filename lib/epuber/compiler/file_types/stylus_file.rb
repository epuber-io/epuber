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
          file_content = Stylus.compile(File.new(abs_source_path))
          self.class.write_to_file(file_content, final_destination_path)
        end
      end
    end
  end
end
