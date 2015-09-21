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
          write_generate(content.to_s)
        end

        def write_generate(content)
          if self.class.write_to_file?(content, final_destination_path)
            UI.print_processing_debug_info("Writing generated content to #{pkg_destination_path}")
            self.class.write_to_file!(content, final_destination_path)
          end
        end
      end
    end
  end
end
