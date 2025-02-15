# frozen_string_literal: true

module Epuber
  class Compiler
    require_relative '../xhtml_processor'

    module FileTypes
      require_relative 'source_file'

      class XHTMLFile < SourceFile
        # @return [Epuber::Book::TocItem]
        #
        attr_accessor :toc_item

        # @return [Array<String>]
        #
        attr_accessor :global_ids

        # @return [Array<String>]
        #
        attr_accessor :global_links

        def initialize(source_path)
          super

          self.global_ids = []
          self.global_links = []
        end

        # @param [Book::Target] target
        # @param [FileResolver] file_resolver
        #
        # @return [Array<String>] list of paths to styles relative to this file
        #
        def default_styles(target, file_resolver)
          default_styles = target.default_styles.map do |default_style_request|
            Array(file_resolver.file_from_request(default_style_request))
          end.flatten

          dirname = Pathname.new(File.dirname(final_destination_path))
          default_styles.map do |style|
            Pathname.new(style.final_destination_path).relative_path_from(dirname).to_s
          end
        end

        # @param [Book::Target] target
        # @param [FileResolver] file_resolver
        #
        # @return [Array<String>] list of paths to styles relative to this file
        #
        def default_scripts(target, file_resolver)
          default_scripts = target.default_scripts.map do |default_style_request|
            Array(file_resolver.file_from_request(default_style_request))
          end.flatten

          dirname = Pathname.new(File.dirname(final_destination_path))
          default_scripts.map do |style|
            Pathname.new(style.final_destination_path).relative_path_from(dirname).to_s
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

          self.class.write_to_file(xhtml_content, abs_source_path) if compilation_context.should_write

          xhtml_content
        end

        # @param [Array<Epuber::Compiler::Problem>] errors
        #
        def process_nokogiri_errors(errors)
          errors.each do |problem|
            UI.warning(problem, location: self)
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

          xhtml_doc, errors = UI.print_step_processing_time('parsing XHTML file') do
            XHTMLProcessor.xml_doc_from_str_with_errors(content, source_path)
          end

          process_nokogiri_errors(errors) if compilation_context.release_build && xhtml_doc.errors.count.positive?

          UI.print_step_processing_time('adding missing elements') do
            XHTMLProcessor.add_missing_root_elements(xhtml_doc, book.title, target.epub_version)
          end

          # resolve links to files, add other linked resources and compute correct path
          UI.print_step_processing_time('resolving links') do
            XHTMLProcessor.resolve_links(xhtml_doc, destination_path, file_resolver.dest_finder)
          end
          UI.print_step_processing_time('resolving image resources') do
            XHTMLProcessor.resolve_images(xhtml_doc, destination_path, file_resolver)
          end
          UI.print_step_processing_time('resolving scripts') do
            XHTMLProcessor.resolve_scripts(xhtml_doc, destination_path, file_resolver)
          end
          UI.print_step_processing_time('resolving stylesheets') do
            XHTMLProcessor.resolve_stylesheets(xhtml_doc, destination_path, file_resolver)
          end

          UI.print_step_processing_time('adding default things') do
            XHTMLProcessor.add_styles(xhtml_doc, default_styles(target, file_resolver))
            XHTMLProcessor.add_scripts(xhtml_doc, default_scripts(target, file_resolver))

            XHTMLProcessor.add_viewport(xhtml_doc, target.default_viewport) unless target.default_viewport.nil?
          end

          XHTMLProcessor.resolve_mathml_namespace(xhtml_doc)

          UI.print_step_processing_time('investigating properties') do
            properties << :remote_resources if XHTMLProcessor.using_remote_resources?(xhtml_doc)
            properties << :scripted if XHTMLProcessor.using_javascript?(xhtml_doc)
            properties << :mathml if XHTMLProcessor.using_mathml?(xhtml_doc)
          end

          xhtml_string = UI.print_step_processing_time('converting to XHTML') do
            xhtml_doc.to_s
          end

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

          if xhtml_string.include?('="$')
            xhtml_doc = XHTMLProcessor.xml_document_from_string(xhtml_string, final_destination_path)
            self.global_ids = XHTMLProcessor.find_global_ids(xhtml_doc)
            self.global_links = XHTMLProcessor.find_global_links(xhtml_doc)
          end

          xhtml_string
        end

        # @param [Compiler::CompilationContext]
        #
        def process(compilation_context)
          write_processed(common_process(load_source(compilation_context), compilation_context))
        end

        # @param [Compiler::CompilationContext] compilation_context
        # @param [Hash<String, XHTMLFile>] global_ids
        #
        def process_global_ids(_compilation_context, global_ids)
          return if self.global_ids.empty? && global_links.empty?

          xhtml_doc = XHTMLProcessor.xml_document_from_string(File.read(final_destination_path), final_destination_path)

          XHTMLProcessor.find_global_ids_nodes(xhtml_doc).each do |node|
            id = node['id']
            node['id'] = id[1..]
          end

          XHTMLProcessor.find_global_links_nodes(xhtml_doc).each do |node|
            href = node['href'][1..]

            dest_file = global_ids[href]
            if dest_file
              rel_path = Pathname(dest_file.final_destination_path.unicode_normalize)
                         .relative_path_from(Pathname(File.dirname(final_destination_path.unicode_normalize))).to_s

              node['href'] = "#{rel_path}##{href}"
            else
              message = "Can't find global id '#{href}' from link in file #{source_path}"
              location = Epuber::Location.new(path: final_destination_path, lineno: node.line)
              UI.error(message, location: location)
            end
          end

          write_processed(xhtml_doc.to_s)
        end
      end
    end
  end
end
