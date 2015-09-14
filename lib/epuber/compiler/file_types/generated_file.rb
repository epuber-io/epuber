# encoding: utf-8


module Epuber
  class Compiler
    module FileTypes
      require_relative 'abstract_file'

      class GeneratedFile < AbstractFile
        # @return [String | #to_s] files content
        #
        attr_accessor :content

        # @param [Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          self.class.write_to_file(content.to_s, final_destination_path)
        end
      end
    end
  end
end
