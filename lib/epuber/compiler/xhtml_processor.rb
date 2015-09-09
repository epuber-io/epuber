# encoding: utf-8

require 'nokogiri'



module Epuber
  class Compiler
    class XHTMLProcessor
      # @param [String] text
      #
      # @return [Nokogiri::XML::Document]
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
    end
  end
end
