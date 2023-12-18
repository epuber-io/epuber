# frozen_string_literal: true

require 'css_parser'

module Epuber
  class Compiler
    module FileTypes
      require_relative 'source_file'

      class CSSFile < SourceFile
        DECLARATION_TO_FILE_GROUP_MAP = {
          'background' => :image,
          'background-image' => :image,
          'list-style' => :image,
          'list-style-image' => :image,
          'content' => :image,
          'cursor' => :image,
          'border-image' => :image,
          'border-image-source' => :image,
          'mask-image' => :image,
          'mask-box-image' => :image,
          'src' => :font,
        }.freeze

        URL_REGEXP = /url\((.+)\)/.freeze

        # @param [Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          return if destination_file_up_to_date?

          write_processed(process_css(File.read(abs_source_path), compilation_context))
        end

        # Processes CSS file, resolves all linked files and adds them to file resolver
        #
        # @param [String] content
        # @param [Compiler::CompilationContext] compilation_context
        #
        # @return [String]
        #
        def process_css(content, compilation_context)
          file_resolver = compilation_context.file_resolver

          parser = UI.print_step_processing_time('css parsing') do
            parser = CssParser::Parser.new
            parser.load_string!(content)
            parser
          end

          # resolve links to files, add other linked resources and compute correct path
          UI.print_step_processing_time('resolving url()') do
            parser.each_rule_set do |rule_set, _media_types|
              declarations = rule_set.instance_eval { @declarations }
              declarations.each do |property, decl_value|
                value = decl_value.to_s
                next unless value =~ URL_REGEXP

                path = Regexp.last_match(1)
                if path.start_with?('"') && path.end_with?('"')
                  path = path[1..-2]
                  quote = '"'
                end
                if path.start_with?("'") && path.end_with?("'")
                  path = path[1..-2]
                  quote = "'"
                end

                next if path.start_with?('data:') || path.start_with?('http://') || path.start_with?('https://')

                resource_group = DECLARATION_TO_FILE_GROUP_MAP[property]
                dirname = File.dirname(destination_path)

                begin
                  new_path = file_resolver.dest_finder.find_file(path, groups: resource_group, context_path: dirname)
                rescue FileFinders::FileNotFoundError, FileFinders::MultipleFilesFoundError
                  new_path = XHTMLProcessor.resolved_link_to_file(path,
                                                                  resource_group,
                                                                  dirname,
                                                                  file_resolver.source_finder).to_s
                  pkg_abs_path = File.expand_path(new_path, dirname).unicode_normalize
                  pkg_new_path = Pathname.new(pkg_abs_path)
                                         .relative_path_from(Pathname.new(file_resolver.source_path))
                                         .to_s

                  file_class = FileResolver.file_class_for(File.extname(new_path))
                  file = file_class.new(pkg_new_path)
                  file.path_type = :manifest
                  file_resolver.add_file(file)
                end

                new_url = FileResolver.renamed_file_with_path(new_path)
                content = content.gsub(value, "url(#{quote}#{new_url}#{quote})")
              end
            end
          end

          content
        end
      end
    end
  end
end
