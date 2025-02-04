# frozen_string_literal: true

require_relative '../book/toc_item'

module Epuber
  class Compiler
    require_relative 'file_resolver'
    require_relative 'generator'

    class NavGenerator < Generator
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
        landmark_cover: { type: 'cover', text: 'Cover page' },
        landmark_start_page: { type: %w[bodymatter ibooks:reader-start-page], text: 'Start Reading' },
        landmark_copyright: { type: 'copyright-page', text: 'Copyright page' },
        landmark_toc: { type: 'toc', text: 'Table of contents' },
      }.freeze

      # Generates XML for toc document, the structure differs depend on epub_version
      #
      # Use method #to_s to generate nice string from XML document
      #
      # @return [Nokogiri::XML::Document]
      #
      def generate
        generate_xml do
          generate_xhtml_content
        end
      end


      private

      # @return [Hash<String, String>]
      #
      def nav_namespaces
        dict = XHTML_NAMESPACES
        dict = dict.merge(XHTML_IBOOKS_NAMESPACES) if @target.ibooks?
        dict
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

      # @param [Array<Epuber::Book::TocItem>] toc_items
      #
      def visit_toc_items(toc_items)
        if toc_items.length.positive? && contains_item_with_title(toc_items)
          @xml.ol do
            toc_items.each do |child_item|
              visit_toc_item(child_item)
            end
          end
        end
      end

      def contains_item_with_title(toc_items)
        toc_items.any? { |a| a.title || contains_item_with_title(a.sub_items) }
      end

      # @param [Epuber::Book::TocItem] toc_item
      #
      def visit_toc_item(toc_item)
        result_file_path = pretty_path_for_toc_item(toc_item)

        if toc_item.title.nil?
          visit_toc_items(toc_item.sub_items)
        else
          @xml.li do
            node_builder = @xml.a(href: result_file_path)
            node_builder.node.inner_html = toc_item.title

            visit_toc_items(toc_item.sub_items)
          end
        end
      end


      # --------------- landmarks -----------------------------

      # @param [Array<Epuber::Book::TocItem>] toc_items
      #
      def landmarks_visit_toc_items(toc_items)
        toc_items.each do |child_item|
          landmarks_visit_toc_item(child_item)
        end
      end

      # @param [Epuber::Book::TocItem] toc_item
      #
      def landmarks_visit_toc_item(toc_item)
        landmarks = toc_item.landmarks
        landmarks.each do |landmark|
          dict = LANDMARKS_MAP[landmark]

          raise "Unknown landmark `#{landmark.inspect}`, supported are #{LANDMARKS_MAP.keys}" if dict.nil?

          types = Array(dict[:type])


          # filter out ibooks specific when the target is not ibooks
          types = types.reject { |type| type.to_s.start_with?('ibooks:') } unless @target.ibooks?

          result_file_path = pretty_path_for_toc_item(toc_item, fragment: false)

          types.each do |type|
            @xml.li do
              @xml.a(dict[:text], 'epub:type' => type, 'href' => result_file_path)
            end
          end
        end

        landmarks_visit_toc_items(toc_item.sub_items)
      end
    end
  end
end
