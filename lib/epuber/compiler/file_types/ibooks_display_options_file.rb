# frozen_string_literal: true

module Epuber
  class Compiler
    module FileTypes
      require_relative 'generated_file'

      class IBooksDisplayOptionsFile < GeneratedFile
        def initialize
          super

          self.destination_path = 'META-INF/com.apple.ibooks.display-options.xml'
          self.path_type = :package
        end

        # @param [Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          gen = MetaInfGenerator.new(compilation_context)
          write_generate(gen.generate_ibooks_display_options_xml)
        end
      end
    end
  end
end
