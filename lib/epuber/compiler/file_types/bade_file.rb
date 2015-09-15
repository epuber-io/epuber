# encoding: utf-8

require 'bade'


module Epuber
  class Compiler
    module FileTypes
      require_relative 'xhtml_file'

      class BadeFile < XHTMLFile
        # @param [Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          target = compilation_context.target
          book = compilation_context.book
          file_resolver = compilation_context.file_resolver

          bade_content = load_source(compilation_context)

          variables = {
            __book: book,
            __target: target,
            __file_resolver: file_resolver,
            __file: self,
            __const: Hash.new { |_hash, key| UI.warning("Undefined constant with key `#{key}`", location: caller_locations[0]) }.merge!(target.constants),
          }

          xhtml_content = Bade::Renderer.from_source(bade_content, source_path)
                                        .with_locals(variables)
                                        .render(new_line: '', indent: '')

          xhtml_content = common_process(xhtml_content, compilation_context)

          self.class.write_to_file(xhtml_content, final_destination_path)
        end
      end
    end
  end
end
