# encoding: utf-8


module Epuber
  class Compiler
    module FileTypes
      require_relative 'source_file'

      class XHTMLFile < SourceFile

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

          XHTMLProcessor.resolve_links(xhtml_doc, destination_path, file_resolver.dest_finder)
          XHTMLProcessor.resolve_images(xhtml_doc, destination_path, file_resolver)

          xhtml_doc.to_xml(indent: 0, encoding: 'UTF-8', save_with: 0)
        end

        # @param [Compiler::CompilationContext]
        #
        def process(compilation_context)
          xhtml_content = File.read(abs_source_path)

          xhtml_content = common_process(xhtml_content, compilation_context)

          self.class.write_to_file(xhtml_content, final_destination_path)
        end
      end
    end
  end
end
