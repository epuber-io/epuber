# encoding: utf-8


module Epuber
  class Compiler
    require_relative '../xhtml_processor'

    module FileTypes
      require_relative 'source_file'

      class XHTMLFile < SourceFile

        # @return [Epuber::Book::TocItem]
        #
        attr_accessor :toc_item

        # @param [Book::Target] target
        # @param [FileResolver] file_resolver
        #
        # @return [Array<String>] list of paths to styles relative to this file
        #
        def default_styles(target, file_resolver)
          default_styles = target.default_styles.map do |default_style_request|
            Array(file_resolver.file_from_request(default_style_request))
          end.flatten

          default_styles.map do |style|
            Pathname.new(style.final_destination_path).relative_path_from(Pathname.new(File.dirname(final_destination_path))).to_s
          end
        end

        # @param [Compiler::CompilationContext] compilation_context
        #
        def load_source(compilation_context)
          xhtml_content = File.read(abs_source_path)

          compilation_context.perform_plugin_things(Transformer, :source_text_file) do |transformer|
            xhtml_content = transformer.call(abs_source_path, xhtml_content, compilation_context)
          end
          
          # perform custom validation
          if compilation_context.should_check
            compilation_context.perform_plugin_things(Checker, :source_text_file) do |checker|
              checker.call(abs_source_path, xhtml_content, compilation_context)
            end
          end


          if compilation_context.should_write
            self.class.write_to_file(xhtml_content, abs_source_path)
          end

          xhtml_content
        end

        # @param [String] content xhtml in string
        # @param [Compiler::CompilationContext] compilation_context
        #
        # @return [String] new xhtml string
        #
        def common_process(content, compilation_context)
          target = compilation_context.target
          book = compilation_context.book
          file_resolver = compilation_context.file_resolver

          xhtml_doc = XHTMLProcessor.xml_document_from_string(content, source_path)
          XHTMLProcessor.add_missing_root_elements(xhtml_doc, book.title, target.epub_version)

          XHTMLProcessor.add_styles(xhtml_doc, default_styles(target, file_resolver))

          XHTMLProcessor.add_viewport(xhtml_doc, target.default_viewport) unless target.default_viewport.nil?
          self.properties << :scripted if XHTMLProcessor.using_javascript?(xhtml_doc)
          self.properties << :remote_resources if XHTMLProcessor.using_remote_resources?(xhtml_doc)

          XHTMLProcessor.resolve_links(xhtml_doc, destination_path, file_resolver.dest_finder)
          XHTMLProcessor.resolve_images(xhtml_doc, destination_path, file_resolver)
          XHTMLProcessor.resolve_scripts(xhtml_doc, destination_path, file_resolver)
          XHTMLProcessor.resolve_stylesheets(xhtml_doc, destination_path, file_resolver)

          xhtml_string = xhtml_doc.to_s

          # perform transformations
          compilation_context.perform_plugin_things(Transformer, :result_text_xhtml_string) do |transformer|
            xhtml_string = transformer.call(final_destination_path, xhtml_string, compilation_context)
          end

          # perform custom validation
          if compilation_context.should_check
            compilation_context.perform_plugin_things(Checker, :result_text_xhtml_string) do |checker|
              checker.call(final_destination_path, xhtml_string, compilation_context)
            end
          end

          xhtml_string
        end

        # @param [Compiler::CompilationContext]
        #
        def process(compilation_context)
          write_processed(common_process(load_source(compilation_context), compilation_context))
        end
      end
    end
  end
end
