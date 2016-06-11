# encoding: utf-8

require 'bade'


module Epuber
  class Compiler
    module FileTypes
      require_relative 'xhtml_file'

      class BadeFile < XHTMLFile
        PRECOMPILED_CACHE_NAME = 'bade_precompiled'

        # @param [Epuber::Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          target = compilation_context.target
          book = compilation_context.book
          file_resolver = compilation_context.file_resolver

          up_to_date = source_file_up_to_date?
          precompiled_exists = File.exist?(precompiled_path)

          variables = {
            __book: book,
            __target: target,
            __file_resolver: file_resolver,
            __file: self,
            __toc_item: toc_item,
            __const: Hash.new { |_hash, key| UI.warning("Undefined constant with key `#{key}`", location: caller_locations[0]) }.merge!(target.constants),
          }

          should_load_from_precompiled = up_to_date && precompiled_exists && compilation_context.incremental_build?

          precompiled = if should_load_from_precompiled
                          begin
                            Bade::Precompiled.from_yaml_file(precompiled_path)
                          rescue LoadError
                            UI.warning("Empty precompiled file at path #{pretty_precompiled_path}", location: self)
                            nil
                          end
                        end

          if !precompiled.nil?
            renderer = Bade::Renderer.from_precompiled(precompiled)
                                     .with_locals(variables)

            xhtml_content = renderer.render(new_line: '', indent: '')
          else
            UI.print_processing_debug_info('Parsing new version of source file') if compilation_context.incremental_build?

            bade_content = load_source(compilation_context)

            renderer = Bade::Renderer.from_source(bade_content, source_path)
                                     .with_locals(variables)

            FileUtils.mkdir_p(File.dirname(precompiled_path))
            renderer.precompiled.write_yaml_to_file(precompiled_path)

            xhtml_content = renderer.render(new_line: '', indent: '')
          end

          write_compiled(common_process(xhtml_content, compilation_context))
          update_metadata!
        end

        # return [Array<String>]
        #
        def find_dependencies
          (super + self.class.find_imports(File.read(abs_source_path))).uniq
        end

        # @return [String]
        #
        def precompiled_path
          File.join(Config.instance.build_cache_path(PRECOMPILED_CACHE_NAME), source_path + '.precompiled.yml')
        end

        def pretty_precompiled_path
          Config.instance.pretty_path_from_project(precompiled_path)
        end

        def self.find_imports(content)
          content.to_enum(:scan, /^\s*import ("|')([^'"]*)("|')/).map { Regexp.last_match[2] }
        end
      end
    end
  end
end
