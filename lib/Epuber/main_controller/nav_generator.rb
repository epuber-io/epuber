require 'nokogiri'

require_relative '../book/toc_item'


module Epuber
  class MainController
    class NavGenerator

      NCX_NAMESPACES = {
        'xmlns' => 'http://www.daisy.org/z3986/2005/ncx/'
      }.freeze

      XHTML_NAMESPACES = {
        'xmlns' => 'http://www.w3.org/1999/xhtml',
        'xmlns:epub' => 'http://www.idpf.org/2007/ops'
      }.freeze

      XHTML_IBOOKS_NAMESPACES = {
        'xmlns:ibooks' => 'http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0',
        'epub:prefix' => 'ibooks: http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0'
      }.freeze


      # @param target [Epuber::Book::Target]
      # @param book [Epuber::Book::Book]
      #
      def initialize(book, target)
        @book = book
        @target = target
      end

      # Generates XML for toc document, the structure differs depend on epub_version
      #
      # Use method #to_s to generate nice string from XML document
      #
      # @return [Nokogiri::XML::Document]
      #
      def generate_nav
        builder = Nokogiri::XML::Builder.new(encoding: 'utf-8') { |xml|
          @xml = xml

          if @target.epub_version >= 3
            generate_xhtml_content
          else
            generate_ncx_content
          end

          @xml = nil
        }

        builder.doc
      end

      # @return [Epuber::Book::File]
      #
      def generate_nav_file
        opf_file = Epuber::Book::File.new(nil)

        opf_file.destination_path = if @target.epub_version >= 3
                                      'nav.xhtml'
                                    else
                                      'nav.ncx'
                                    end

        opf_file.content = generate_nav
        opf_file
      end



      private

      # @return [Hash<String, String>]
      #
      def nav_namespaces
        if @target.epub_version >= 3
          dict = XHTML_NAMESPACES
          dict = dict.merge(XHTML_IBOOKS_NAMESPACES) if @target.is_ibooks?
          dict
        else
          NCX_NAMESPACES
        end
      end

      def generate_xhtml_content
        @xml.doc.create_internal_subset('html', nil, nil)
        @xml.html(nav_namespaces) {
          @xml.head {
            @xml.title_(@book.title)
          }
          @xml.body {
            @xml.nav('epub:type' => 'toc') {
              visit_toc_items(@book.root_toc.child_items)
            }
          }
        }
      end

      def generate_ncx_content
        @xml.doc.create_internal_subset('ncx',
                                       '-//NISO//DTD ncx 2005-1//EN',
                                       'http://www.daisy.org/z3986/2005/ncx-2005-1.dtd')

        @xml.ncx(nav_namespaces, version: '2005-1') {

          # head
          @xml.head {
            @xml.meta(name: 'dtb:uid', content: @target.isbn)

            # TODO: try without these
            @xml.meta(name: 'dtb:depth', content: '1')
            @xml.meta(name: 'dtb:totalPageCount', content: '1')
            @xml.meta(name: 'dtb:maxPageNumber', content: '1')
          }

          # title
          @xml.docTitle {
            @xml.text_(@book.title)
          }

          @nav_play_order = 1
          @nav_nav_point_id = 1

          # nav map
          @xml.navMap {
            visit_toc_items(@book.root_toc.child_items)
          }
        }
      end

      # @param toc_items [Array<Epuber::Book::TocItem>]
      #
      def visit_toc_items(toc_items)
        iterate_lambda = lambda {
          toc_items.each { |child_item|
            visit_toc_item(child_item)
          }
        }

        if @target.epub_version >= 3 && toc_items.length > 0
          @xml.ol {
            iterate_lambda.call
          }
        else
          iterate_lambda.call
        end
      end

      # @param toc_item [Epuber::Book::TocItem]
      #
      def visit_toc_item(toc_item)
        if toc_item.title.nil?
          visit_toc_items(toc_item.child_items)
        elsif @target.epub_version >= 3
          @xml.li {
            @xml.a(toc_item.title, href: toc_item.file_obj.destination_path)

            visit_toc_items(toc_item.child_items)
          }
        else
          @xml.navPoint(id: "navPoint_#{@nav_nav_point_id}", playOrder: @nav_play_order) {
            @xml.navLabel {
              @xml.text_(toc_item.title)
            }
            @xml.content(src: toc_item.file_obj.destination_path)

            @nav_nav_point_id += 1
            @nav_play_order += 1

            visit_toc_items(toc_item.child_items)
          }
        end
      end
    end
  end
end
