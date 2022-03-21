# frozen_string_literal: true

require 'coffee-script'

module Epuber
  class Compiler
    module FileTypes
      require_relative 'source_file'

      class CoffeeScriptFile < SourceFile
        # @param [Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          return if destination_file_up_to_date?

          write_compiled(CoffeeScript.compile(File.new(abs_source_path)))

          update_metadata!
        end
      end
    end
  end
end
