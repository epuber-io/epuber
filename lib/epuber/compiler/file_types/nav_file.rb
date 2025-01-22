# frozen_string_literal: true

module Epuber
  class Compiler
    module FileTypes
      require_relative 'generated_file'

      class NavAbstractFile < GeneratedFile
        # @return [Class]
        #
        attr_reader :generator_type

        # @param [String] filename
        # @param [Class] generator Class of generator (subclass of Epuber::Compiler::Generator)
        #
        def initialize(filename, generator_type, properties = [])
          super()

          @generator_type = generator_type

          self.properties = properties
          self.destination_path = filename
          self.path_type = :manifest
        end

        # @param [Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          result = generator_type.new(compilation_context)
                                 .generate
                                 .to_s

          write_generate(result)
        end
      end

      class NavFile < NavAbstractFile
        def initialize
          super('nav.xhtml', NavGenerator, [:navigation])
        end
      end

      class NcxFile < NavAbstractFile
        def initialize
          super('toc.ncx', NcxGenerator, [])
        end
      end
    end
  end
end
