
require_relative 'generator'
require_relative '../book/toc_item'


module Epuber
  class Compiler
    class NavGenerator < Generator

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

      # resource page http://www.idpf.org/epub/301/spec/epub-contentdocs.html#sec-xhtml-nav-def-types-landmarks
      LANDMARKS_MAP = {
        landmark_cover:      { type: 'cover', text: 'Cover page' },
        landmark_start_page: { type: %w(bodymatter ibooks:reader-start-page), text: 'Start Reading' },
        landmark_copyright:  { type: 'copyright-page', text: 'Copyright page' },
        landmark_toc:        { type: 'toc', text: 'Table of contents' },
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
        generate_xml {
          if @target.epub_version >= 3
            generate_xhtml_content
          else
            generate_ncx_content
          end
        }
      end

      # @return [Epuber::Book::File]
      #
      def generate_nav_file
        nav_file = Epuber::Book::File.new(nil)

        nav_file.destination_path = if @target.epub_version >= 3
                                      'nav.xhtml'
                                    else
                                      'nav.ncx'
                                    end

        nav_file.content = generate_nav
        nav_file.add_property('nav')
        nav_file
      end



      private

      # @return [Hash<String, String>]
      #
      def nav_namespaces
        if @target.epub_version >= 3
          dict = XHTML_NAMESPACES.dup
          dict.merge!(XHTML_IBOOKS_NAMESPACES) if @target.is_ibooks?
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

            # toc
            @xml.nav('epub:type' => 'toc') {
              visit_toc_items(@book.root_toc.child_items)
            }

            # landmarks
            @xml.nav('epub:type' => 'landmarks') {
              @xml.ol {
                landmarks_visit_toc_item(@book.root_toc)
              }
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
            @xml.meta(name: 'dtb:uid', content: "urn:isbn:#{@target.isbn}")
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


      # --------------- landmarks -----------------------------

      # @param toc_items [Array<Epuber::Book::TocItem>]
      #
      def landmarks_visit_toc_items(toc_items)
        toc_items.each { |child_item|
          landmarks_visit_toc_item(child_item)
        }
      end

      # @param toc_item [Epuber::Book::TocItem]
      #
      def landmarks_visit_toc_item(toc_item)
        landmarks = toc_item.landmarks
        landmarks.each { |landmark|
          dict = LANDMARKS_MAP[landmark]

          raise "Unknown landmark `#{landmark.inspect}`, supported are #{LANDMARKS_MAP}" if dict.nil?

          map_type = dict[:type]
          types = if map_type.is_a?(Array)
                    map_type
                  else
                    [map_type]
                  end

          types.select! { |type| !type.to_s.start_with?('ibooks:') } unless @target.is_ibooks?

          types.each { |type|

            @xml.li {
              @xml.a(dict[:text], 'epub:type' => type, 'href' => toc_item.file_obj.destination_path)
            }
          }
        }

        landmarks_visit_toc_items(toc_item.child_items)
      end
    end
  end
end
