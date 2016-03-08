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
          Stylus.define('__is_debug', !compilation_context.release_build)
          Stylus.define('__is_verbose_mode', compilation_context.verbose?)
          Stylus.define('__target_name', compilation_context.target.name)
          Stylus.define('__book_title', compilation_context.book.title)

          write_compiled(Stylus.compile(File.new(abs_source_path)))
        end
      end
    end
  end
end
