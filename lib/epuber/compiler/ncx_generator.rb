# frozen_string_literal: true

require_relative '../book/toc_item'

module Epuber
  class Compiler
    class NcxGenerator < Generator
      NCX_NAMESPACES = {
        'xmlns' => 'http://www.daisy.org/z3986/2005/ncx/',
      }.freeze

      def generate
        generate_xml do
          _generate_ncx_content
        end
      end

      private

      def _generate_ncx_content
        @xml.doc.create_internal_subset('ncx',
                                        '-//NISO//DTD ncx 2005-1//EN',
                                        'http://www.daisy.org/z3986/2005/ncx-2005-1.dtd')

        @xml.ncx(NCX_NAMESPACES, version: '2005-1') do
          # head
          @xml.head do
            @xml.meta(name: 'dtb:uid', content: @target.identifier || "urn:isbn:#{@target.isbn}")
          end

          # title
          @xml.docTitle do
            @xml.text_(@book.title)
          end

          @nav_nav_point_id = 1

          # nav map
          @xml.navMap do
            _visit_toc_items(@target.root_toc.sub_items)
          end
        end
      end

      # @param [Array<Epuber::Book::TocItem>] toc_items
      #
      def _visit_toc_items(toc_items)
        toc_items.each do |child_item|
          _visit_toc_item(child_item)
        end
      end

      # @param [Epuber::Book::TocItem] toc_item
      #
      def _visit_toc_item(toc_item)
        result_file_path = pretty_path_for_toc_item(toc_item)

        if toc_item.title.nil?
          _visit_toc_items(toc_item.sub_items)
        else
          @xml.navPoint(id: "navPoint_#{@nav_nav_point_id}", playOrder: @nav_nav_point_id.to_s) do
            @xml.navLabel do
              node_builder = @xml.text_
              node_builder.node.inner_html = toc_item.title
            end
            @xml.content(src: result_file_path)

            @nav_nav_point_id += 1

            _visit_toc_items(toc_item.sub_items)
          end
        end
      end
    end
  end
end
