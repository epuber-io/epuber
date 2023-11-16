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

        # @param [Book::Target] target
        # @param [FileResolver] file_resolver
        #
        # @return [Array<String>] list of paths to styles relative to this file
        #
        def default_scripts(target, file_resolver)
          default_scripts = target.default_scripts.map do |default_style_request|
            Array(file_resolver.file_from_request(default_style_request))
          end.flatten

          default_scripts.map do |style|
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

          if compilation_context.release_build && xhtml_doc.errors.count > 0
            process_nokogiri_errors(errors)
          end

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
            self.properties << :remote_resources if XHTMLProcessor.using_remote_resources?(xhtml_doc)
            self.properties << :scripted if XHTMLProcessor.using_javascript?(xhtml_doc)
            self.properties << :mathml if XHTMLProcessor.using_mathml?(xhtml_doc)
          end

          xhtml_string = UI.print_step_processing_time('converting to XHTML') do
             xhtml_doc.to_s
          end

          # perform transformations
          UI.print_step_processing_time('performing final transformations') do
            compilation_context.perform_plugin_things(Transformer, :result_text_xhtml_string) do |transformer|
              xhtml_string = transformer.call(final_destination_path, xhtml_string, compilation_context)
            end
          end

          # perform custom validation
          if compilation_context.should_check
            UI.print_step_processing_time('performing final validations') do
              compilation_context.perform_plugin_things(Checker, :result_text_xhtml_string) do |checker|
                checker.call(final_destination_path, xhtml_string, compilation_context)
              end
            end
          end

          if xhtml_string.include?('id="$')
            xhtml_doc = XHTMLProcessor.xml_document_from_string(xhtml_string, final_destination_path)
            self.global_ids = XHTMLProcessor.find_global_ids(xhtml_doc)
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
