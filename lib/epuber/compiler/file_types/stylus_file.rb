# encoding: utf-8

require 'epuber-stylus'


module Epuber
  class Compiler
    module FileTypes
      require_relative 'source_file'

      class StylusFile < SourceFile
        # @param [Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          return if destination_file_up_to_date?

          Stylus.define('__is_debug', !compilation_context.release_build)
          Stylus.define('__is_verbose_mode', compilation_context.verbose?)
          Stylus.define('__target_name', compilation_context.target.name)
          Stylus.define('__book_title', compilation_context.book.title)

          write_compiled(Stylus.compile(File.new(abs_source_path)))

          update_metadata!
        end

        def find_dependencies
          self.class.find_imports(File.read(abs_source_path))
        end

        # @return [Array<String>]
        #
        def self.find_imports(content)
          content.to_enum(:scan, /^\s*@import ("|')([^'"]*)("|')/).map { Regexp.last_match[2] }
        end
      end
    end
  end
end
