# encoding: utf-8

require 'nokogiri'
require 'uri'


module Epuber
  class Compiler
    require_relative 'file_finders/normal'

    class XHTMLProcessor
      class UnparseableLinkError < StandardError; end

      # Method for parsing incomplete XML, supports multiple root elements
      #
      # @warning Because of nature of XML, when input string don't contain root element, it will create own called `body`, since it will be used in next steps.
      #
      # @param [String] text  input XHTML text
      #
      # @return [Nokogiri::XML::Document] parsed document
      #
      def self.xml_document_from_string(text, file_path = nil)
        if /\A[\n\r ]+(<\?xml)/ =~ text
          UI.warning('XML header must be at the beginning of document', location: UI::Location.new(file_path, 1))

          text = text.lstrip
        end

        xml_header = ''
        if /\A\s*(<\?xml[^>]*\?>)/ =~ text
          match = Regexp.last_match
          xml_header = text[match.begin(1)...match.end(1)]
          text[match.begin(1)...match.end(1)] = ''
        end

        doctypes = []
        while /(\n|\?>|\A)?(<!DOCTYPE [^>]*>\n*)/ =~ text
          doctypes << $2.strip

          match = Regexp.last_match
          text[match.begin(2)...match.end(2)] = ''
        end

        before = ([xml_header] + doctypes).compact.join("\n")
        unless before.empty?
          before = before + "\n"
        end

        parse_options = Nokogiri::XML::ParseOptions::DEFAULT_XML |
                        Nokogiri::XML::ParseOptions::NOERROR | # to silence any errors or warnings printing into console
                        Nokogiri::XML::ParseOptions::NOWARNING

        doc = Nokogiri::XML("#{before}<root>#{text}</root>", nil, nil, parse_options)
        doc.encoding = 'UTF-8'
        doc.file_path = file_path

        root = root_node = doc.root
        root_elements = root.children.select { |a| a.element? || a.comment? }

        if root_elements.count == 1
          doc.root = root_elements.first
        elsif root_node.at_css('body').nil?
          root_node.node_name = 'body'
        end

        doc
      end


      # Method to add all missing items in XML root
      #
      # Required items:
      #   - html (with all namespaces and other attributes)
      #   - body
      #     - head (with title)
      #
      # @param [Nokogiri::XML::Document] xhtml_doc  input XML document to work with
      # @param [String] title  title of this document, since this is required by EPUB specification
      # @param [Epuber::Version] epub_version  version of result EPUB
      #
      # @return nil
      #
      def self.add_missing_root_elements(xhtml_doc, title, epub_version)
        # add missing body element
        if xhtml_doc.at_css('body').nil?
          xhtml_doc.root.surround_with_element('body')
        end

        # add missing root html element
        if xhtml_doc.at_css('html').nil?
          attrs               = {}
          attrs['xmlns']      = 'http://www.w3.org/1999/xhtml'
          attrs['xmlns:epub'] = 'http://www.idpf.org/2007/ops' if epub_version >= 3
          xhtml_doc.root.surround_with_element('html', attrs)
        end

        # add missing head in html
        if xhtml_doc.at_css('html > head').nil?
          html = xhtml_doc.css('html').first
          head = xhtml_doc.create_element('head')
          head << xhtml_doc.create_element('title', title)
          head << xhtml_doc.create_element('meta', charset: 'utf-8') if epub_version >= 3.0

          html.children.first.before(head)
        end

        # https://github.com/IDPF/epubcheck/issues/631
        if epub_version < 3.0
          xhtml_doc.internal_subset.remove unless xhtml_doc.internal_subset.nil?
          xhtml_doc.create_internal_subset('html', "-//W3C//DTD XHTML 1.1//EN", "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd")
        end
      end

      # Method for adding style sheets with links, method will not add duplicate items
      #
      # @param [Nokogiri::XML::Document] xhtml_doc  input XML document to work with
      # @param [Array<String>] styles  links to files
      #
      # @return nil
      #
      def self.add_styles(xhtml_doc, styles)
        head  = xhtml_doc.at_css('html > head')
        old_links = head.css('link[rel="stylesheet"]').map { |node| node['href'] }

        links_to_add = styles - old_links

        links_to_add.each do |path|
          head << xhtml_doc.create_element('link', href: path, rel: 'stylesheet', type: 'text/css')
        end
      end

      # Method for adding scripts with links, method will not add duplicate items
      #
      # @param [Nokogiri::XML::Document] xhtml_doc  input XML document to work with
      # @param [Array<String>] styles  links to files
      #
      # @return nil
      #
      def self.add_scripts(xhtml_doc, scripts)
        head  = xhtml_doc.at_css('html > head')
        old_links = head.css('script').map { |node| node['src'] }

        links_to_add = scripts - old_links

        links_to_add.each do |path|
          head << xhtml_doc.create_element('script', src: path, type: 'text/javascript')
        end
      end

      # Adds viewport meta tag to head of some document, but only if there is not some existing tag
      #
      # @param [Nokogiri::XML::Document] xhtml_doc
      # @param [Epuber::Size] viewport_size
      #
      def self.add_viewport(xhtml_doc, viewport_size)
        head = xhtml_doc.at_css('html > head')
        return unless head.at_css("meta[name='viewport']").nil?

        s = viewport_size
        head << xhtml_doc.create_element('meta', name: 'viewport', content: "width=#{s.width},height=#{s.height}")
      end

      # Method which will resolve path to file from pattern
      #
      # @param [String] path  pattern or path of the file
      # @param [Symbol | Array<Symbol>] groups  groups of the searching file, could be for example :image when searching for file from tag <img>
      # @param [String] file_path  path to file from which is searching for other file
      # @param [Epuber::Compiler::FileFinder] file_finder  finder for searching for files
      #
      # @raise UnparseableLinkError, FileFinder::FileNotFoundError, FileFinder::MultipleFilesFoundError
      #
      # @return [URI] resolved path to file or remote web page
      #
      def self.resolved_link_to_file(path, groups, file_path, file_finder)
        raise FileFinders::FileNotFoundError.new(path, file_path) if path.empty?

        begin
          uri = URI(path)
        rescue URI::InvalidURIError
          begin
            uri = URI(URI::encode(path))
          rescue URI::InvalidURIError
            # skip not valid uri
            raise UnparseableLinkError, "Unparseable link `#{path}`"
          end
        end

        # skip uri with scheme (links to web pages)
        return uri unless uri.scheme.nil?

        # skip empty path
        return uri if uri.path.empty? && !uri.fragment.nil? && !uri.fragment.empty?

        uri.path = file_finder.find_file(uri.path, groups: groups, context_path: file_path)

        uri
      end

      # Resolves all links to files in XHTML document and returns the valid and resolved versions
      #
      # @param [Nokogiri::XML::Document] xhtml_doc  input XML document to work with
      # @param [String] tag_name  CSS selector for tag
      # @param [String] attribute_name  name of attribute
      # @param [Symbol | Array<Symbol>] groups  groups of the searching file, could be for example :image when searching for file from tag <img>
      # @param [String] file_path  path to file from which is searching for other file
      # @param [Epuber::Compiler::FileFinder] file_finder  finder for searching for files
      #
      # @return [Array<URI>] resolved links
      #
      def self.resolve_links_for(xhtml_doc, tag_name, attribute_name, groups, file_path, file_finder)
        founded_links = []

        xhtml_doc.css("#{tag_name}[#{attribute_name}]").each do |node|
          begin
            src = node[attribute_name]
            # @type [String] src

            next if src.nil?

            target_file = resolved_link_to_file(src, groups, file_path, file_finder)
            founded_links << target_file

            node[attribute_name] = target_file.to_s
          rescue UnparseableLinkError, FileFinders::FileNotFoundError, FileFinders::MultipleFilesFoundError => e
            UI.warning(e.to_s, location: node)

            # skip not found files
            next
          end
        end

        founded_links
      end

      # Resolves all links to files in XHTML document and returns the valid and resolved versions
      #
      # @param [Nokogiri::XML::Document] xhtml_doc  input XML document to work with
      # @param [String] file_path  path to file from which is searching for other file
      # @param [Epuber::Compiler::FileFinder] file_finder  finder for searching for files
      #
      # @return [Array<URI>] resolved links
      #
      def self.resolve_links(xhtml_doc, file_path, file_finder)
        [
          resolve_links_for(xhtml_doc, 'a', 'href', :text, file_path, file_finder),
          resolve_links_for(xhtml_doc, 'map > area', 'href', :text, file_path, file_finder),
        ].flatten
      end

      # @param [Nokogiri::XML::Document] xhtml_doc  input XML document to work with
      #
      # @return [Bool]
      #
      def self.using_javascript?(xhtml_doc)
        !xhtml_doc.at_css('script').nil?
      end

      def self.using_remote_resources?(xhtml_doc)
        regexp = %r{^[^:/?#]+://.*}

        result = false
        result ||= xhtml_doc.css('[src]').any? { |node| node['src'] =~ regexp }
        result ||= xhtml_doc.css('link[href]').any? { |node| node['href'] =~ regexp }
        result
      end

      # @param [Nokogiri::XML::Document] xhtml_doc  input XML document to work with
      #
      # @return [Bool]
      #
      def self.using_mathml?(xhtml_doc)
        !xhtml_doc.at_css('math|math', 'math' => 'http://www.w3.org/1998/Math/MathML').nil?
      end

      def self.resolve_mathml_namespace(xhtml_doc)
        xhtml_doc.css('math').each do |math_node|
          math_node.add_namespace('xmlns', 'http://www.w3.org/1998/Math/MathML')
        end
      end

      # @param [Nokogiri::XML::Document] xhtml_doc
      # @param [String] file_path path of referring file
      # @param [FileResolver] file_resolver
      #
      # @return nil
      #
      def self.resolve_images(xhtml_doc, file_path, file_resolver)
        resolve_resources_in('img', 'src', :image, xhtml_doc, file_path, file_resolver)
      end

      # @param [Nokogiri::XML::Document] xhtml_doc
      # @param [String] file_path path of referring file
      # @param [FileResolver] file_resolver
      #
      # @return nil
      #
      def self.resolve_scripts(xhtml_doc, file_path, file_resolver)
        resolve_resources_in('script', 'src', :script, xhtml_doc, file_path, file_resolver)
      end

      # @param [Nokogiri::XML::Document] xhtml_doc
      # @param [String] file_path path of referring file
      # @param [FileResolver] file_resolver
      #
      # @return nil
      #
      def self.resolve_stylesheets(xhtml_doc, file_path, file_resolver)
        resolve_resources_in('link[rel="stylesheet"]', 'href', :style, xhtml_doc, file_path, file_resolver)
      end

      def self.resolve_resources_in(node_css_query, attribute_name, resource_group, xhtml_doc, file_path, file_resolver)
        dirname = File.dirname(file_path)

        xhtml_doc.css(node_css_query).each do |img|
          path = img[attribute_name]
          next if path.nil?

          begin
            new_path = file_resolver.dest_finder.find_file(path, groups: resource_group, context_path: dirname)

          rescue UnparseableLinkError, FileFinders::FileNotFoundError, FileFinders::MultipleFilesFoundError
            begin
              new_path = resolved_link_to_file(path, resource_group, dirname, file_resolver.source_finder).to_s
              pkg_abs_path = File.expand_path(new_path, dirname).unicode_normalize
              pkg_new_path = Pathname.new(pkg_abs_path).relative_path_from(Pathname.new(file_resolver.source_path)).to_s

              file_class = FileResolver.file_class_for(File.extname(new_path))
              file = file_class.new(pkg_new_path)
              file.path_type = :manifest
              file_resolver.add_file(file)

              new_path = FileResolver::renamed_file_with_path(new_path)

            rescue UnparseableLinkError, FileFinders::FileNotFoundError, FileFinders::MultipleFilesFoundError => e
              UI.warning(e.to_s, location: img)

              next
            end
          end

          img[attribute_name] = new_path
        end
      end
    end
  end
end
