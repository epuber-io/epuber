# frozen_string_literal: true

module Epuber
  class Compiler
    module FileTypes
      require_relative 'generated_file'

      class NavFile < GeneratedFile

        # @return [Epuber::Version]
        #
        attr_reader :epub_version

        # @param [Epuber::Version] epub_version
        #
        def initialize(epub_version)
          super()

          @epub_version = epub_version

          properties << :navigation

          self.destination_path = if epub_version >= 3
                                    'nav.xhtml'
                                  else
                                    'nav.ncx'
                                  end

          self.path_type = :manifest
        end

        # @param [Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          gen = NavGenerator.new(compilation_context)
          write_generate(gen.generate_nav.to_s)
        end
      end
    end
  end
end
