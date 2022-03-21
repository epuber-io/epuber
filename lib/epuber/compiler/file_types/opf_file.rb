# frozen_string_literal: true

module Epuber
  class Compiler
    module FileTypes
      require_relative 'generated_file'

      class OPFFile < GeneratedFile

        def initialize
          super

          self.destination_path = File.join(Epuber::Compiler::EPUB_CONTENT_FOLDER, 'content.opf')
          self.path_type = :package
        end

        # @param [Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          gen = OPFGenerator.new(compilation_context)
          write_generate(gen.generate_opf.to_s)
        end
      end
    end
  end
end
