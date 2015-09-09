# encoding: utf-8

require 'nokogiri'



module Epuber
  class Compiler
    class XHTMLProcessor
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

    end
  end
end
