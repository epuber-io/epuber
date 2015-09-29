# encoding: utf-8


module Epuber
  class Compiler
    module FileTypes
      require_relative 'generated_file'

      class ContainerXMLFile < GeneratedFile
        def initialize
          super

          self.destination_path = 'META-INF/container.xml'
          self.path_type = :package
        end

        # @param [Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          gen = MetaInfGenerator.new(compilation_context)
          write_generate(gen.generate_container_xml)
        end
      end
    end
  end
end
