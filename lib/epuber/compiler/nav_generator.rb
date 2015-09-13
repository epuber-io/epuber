# encoding: utf-8

require_relative 'generator'
require_relative '../book/toc_item'


module Epuber
  class Compiler
    class NavGenerator < Generator
      require_relative 'file_resolver'

      NCX_NAMESPACES = {
        'xmlns' => 'http://www.daisy.org/z3986/2005/ncx/',
      }.freeze

      XHTML_NAMESPACES = {
        'xmlns' => 'http://www.w3.org/1999/xhtml',
        'xmlns:epub' => 'http://www.idpf.org/2007/ops',
      }.freeze

      XHTML_IBOOKS_NAMESPACES = {
        'xmlns:ibooks' => 'http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0',
        'epub:prefix' => 'ibooks: http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0',
      }.freeze

      # resource page http://www.idpf.org/epub/301/spec/epub-contentdocs.html#sec-xhtml-nav-def-types-landmarks
      LANDMARKS_MAP = {
        landmark_cover:      { type: 'cover', text: 'Cover page' },
        landmark_start_page: { type: %w(bodymatter ibooks:reader-start-page), text: 'Start Reading' },
        landmark_copyright:  { type: 'copyright-page', text: 'Copyright page' },
        landmark_toc:        { type: 'toc', text: 'Table of contents' },
      }.freeze

      # Generates XML for toc document, the structure differs depend on epub_version
      #
      # Use method #to_s to generate nice string from XML document
      #
      # @return [Nokogiri::XML::Document]
      #
      def generate_nav
        generate_xml do
          if @target.epub_version >= 3
            generate_xhtml_content
          else
            generate_ncx_content
          end
        end
      end

      # @return [Epuber::Book::File]
      #
      def generate_nav_file
        nav_file = Epuber::Compiler::FileTypes::GeneratedFile.new
        nav_file.destination_path = if @target.epub_version >= 3
                                      'nav.xhtml'
                                    else
                                      'nav.ncx'
                                    end
        nav_file.content = generate_nav
        nav_file.path_type = :manifest
        nav_file.properties << :navigation
        nav_file
      end



      private

      # @return [Hash<String, String>]
      #
      def nav_namespaces
        if @target.epub_version >= 3
          dict = XHTML_NAMESPACES
          dict = dict.merge(XHTML_IBOOKS_NAMESPACES) if @target.ibooks?
          dict
        else
          NCX_NAMESPACES
        end
      end

      # @return nil
      #
      def generate_xhtml_content
        @xml.doc.create_internal_subset('html', nil, nil)
        @xml.html(nav_namespaces) do
          @xml.head do
            @xml.title_(@book.title)
          end
          @xml.body do
            # toc
            @xml.nav('epub:type' => 'toc') do
              visit_toc_items(@target.root_toc.sub_items)
            end

            # landmarks
            @xml.nav('epub:type' => 'landmarks') do
              @xml.ol do
                landmarks_visit_toc_item(@target.root_toc)
              end
            end
          end
        end
      end

      def generate_ncx_content
        @xml.doc.create_internal_subset('ncx',
                                        '-//NISO//DTD ncx 2005-1//EN',
                                        'http://www.daisy.org/z3986/2005/ncx-2005-1.dtd')

        @xml.ncx(nav_namespaces, version: '2005-1') do
          # head
          @xml.head do
            @xml.meta(name: 'dtb:uid', content: (@target.identifier || "urn:isbn:#{@target.isbn}"))
          end

          # title
          @xml.docTitle do
            @xml.text_(@book.title)
          end

          @nav_nav_point_id = 1

          # nav map
          @xml.navMap do
            visit_toc_items(@target.root_toc.sub_items)
          end
        end
      end

      # @param toc_items [Array<Epuber::Book::TocItem>]
      #
      def visit_toc_items(toc_items)
        iterate_lambda = lambda do
          toc_items.each do |child_item|
            visit_toc_item(child_item)
          end
        end

        if @target.epub_version >= 3 && toc_items.length > 0
          @xml.ol do
            iterate_lambda.call
          end
        else
          iterate_lambda.call
        end
      end

      # @param toc_item [Epuber::Book::TocItem]
      #
      def visit_toc_item(toc_item)
        result_file = @file_resolver.find_file_from_request(toc_item.file_request)

        if toc_item.title.nil?
          visit_toc_items(toc_item.sub_items)
        elsif @target.epub_version >= 3
          @xml.li do
            @xml.a(toc_item.title, href: pretty_path(result_file))

            visit_toc_items(toc_item.sub_items)
          end
        else
          @xml.navPoint(id: "navPoint_#{@nav_nav_point_id}") do
            @xml.navLabel do
              @xml.text_(toc_item.title)
            end
            @xml.content(src: pretty_path(result_file))

            @nav_nav_point_id += 1

            visit_toc_items(toc_item.sub_items)
          end
        end
      end


      # --------------- landmarks -----------------------------

      # @param toc_items [Array<Epuber::Book::TocItem>]
      #
      def landmarks_visit_toc_items(toc_items)
        toc_items.each do |child_item|
          landmarks_visit_toc_item(child_item)
        end
      end

      # @param toc_item [Epuber::Book::TocItem]
      #
      def landmarks_visit_toc_item(toc_item)
        landmarks = toc_item.landmarks
        landmarks.each do |landmark|
          dict = LANDMARKS_MAP[landmark]

          raise "Unknown landmark `#{landmark.inspect}`, supported are #{LANDMARKS_MAP.keys}" if dict.nil?

          map_type = dict[:type]
          types    = if map_type.is_a?(Array)
                       map_type
                     else
                       [map_type]
                     end

          # filter out ibooks specific when the target is not ibooks
          types.reject! { |type| type.to_s.start_with?('ibooks:') } unless @target.ibooks?

          result_file = @file_resolver.find_file_from_request(toc_item.file_request)

          types.each do |type|
            @xml.li do
              @xml.a(dict[:text], 'epub:type' => type, 'href' => pretty_path(result_file))
            end
          end
        end

        landmarks_visit_toc_items(toc_item.sub_items)
      end
    end
  end
end
