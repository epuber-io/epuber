# encoding: utf-8

require 'nokogiri'


module Epuber
  class Compiler
    require_relative 'file_finder'

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
      def self.xml_document_from_string(text)
        doc = Nokogiri::XML.parse(text)
        doc.encoding = 'UTF-8'

        fragment = Nokogiri::XML.fragment(text)
        root_elements = fragment.children.select { |el| el.element? }

        if root_elements.count == 1
          doc.root = root_elements.first
        elsif fragment.at_css('body').nil?
          doc.root = doc.create_element('body')

          fragment.children.select do |child|
            child.element? || child.comment? || child.text?
          end.each do |child|
            doc.root.add_child(child)
          end
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

          html.children.first.before(head)
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

      # Method which will resolve path to file from pattern
      #
      # @param [String] path  pattern or path of the file
      # @param [Symbol | Array<Symbol>] groups  groups of the searching file, could be for example :image when searching for file from tag <img>
      # @param [String] context_path  path to file from which is searching for other file
      # @param [Epuber::Compiler::FileFinder] file_finder  finder for searching for files
      #
      # @raise UnparseableLinkError, FileFinder::FileNotFoundError, FileFinder::MultipleFilesFoundError
      #
      # @return [URI] resolved path to file or remote web page
      #
      def self.resolved_link_to_file(path, groups, context_path, file_finder)
        raise FileFinder::FileNotFoundError.new(path, context_path) if path.empty?

        begin
          uri = URI(path)
        rescue
          begin
            uri = URI(URI::encode(path))
          rescue
            # skip not valid uri
            raise UnparseableLinkError, "Unparseable link `#{path}`"
          end
        end

        # skip uri with scheme (links to web pages)
        return uri unless uri.scheme.nil?

        # skip empty path
        return uri if uri.path.empty? && !uri.fragment.nil? && !uri.fragment.empty?

        uri.path = file_finder.find_file(uri.path, groups: groups, context_path: context_path)

        uri
      end

      # Resolves all links to files in XHTML document and returns the valid and resolved versions
      #
      # @param [Nokogiri::XML::Document] xhtml_doc  input XML document to work with
      # @param [String] tag_name  CSS selector for tag
      # @param [String] attribute_name  name of attribute
      # @param [Symbol | Array<Symbol>] groups  groups of the searching file, could be for example :image when searching for file from tag <img>
      # @param [String] context_path  path to file from which is searching for other file
      # @param [Epuber::Compiler::FileFinder] file_finder  finder for searching for files
      #
      # @return [Array<URI>] resolved links
      #
      def self.resolve_links_for(xhtml_doc, tag_name, attribute_name, groups, context_path, file_finder)
        founded_links = []

        xhtml_doc.css("#{tag_name}[#{attribute_name}]").each do |node|
          begin
            src = node[attribute_name]
            # @type [String] src

            next if src.nil?

            target_file = resolved_link_to_file(src, groups, context_path, file_finder)
            founded_links << target_file

            node[attribute_name] = target_file.to_s
          rescue UnparseableLinkError, FileFinder::FileNotFoundError, FileFinder::MultipleFilesFoundError => e
            UI.warning(e.to_s, location: node)

            # skip not found files
            next
          end
        end

        founded_links
      end
    end
  end
end
