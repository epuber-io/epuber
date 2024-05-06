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
          parser = UI.print_step_processing_time('css parsing') do
            parser = CssParser::Parser.new
            parser.load_string!(content)
            parser
          end

          # resolve links to files, add other linked resources and compute correct path
          UI.print_step_processing_time('resolving url()') do
            parser.each_rule_set do |rule_set, _media_types|
              # @type [CssParser::RuleSet::Declarations]
              declarations = rule_set.instance_eval { @declarations }
              declarations.each do |property, decl_value|
                # @type [String]
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
                new_url = SourceFile.resolve_relative_file(destination_path,
                                                           path,
                                                           compilation_context.file_resolver,
                                                           group: resource_group,
                                                           location: self)

                content = content.gsub(value, "url(#{quote}#{new_url}#{quote})") if new_url
              end
            end
          end

          content
        end
      end
    end
  end
end
