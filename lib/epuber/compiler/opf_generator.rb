# encoding: utf-8

require 'time'

require 'mime-types'

require_relative 'generator'
require_relative '../book/toc_item'


module Epuber
  class Compiler
    class OPFGenerator < Generator

      EPUB2_NAMESPACES = {
        'xmlns'     => 'http://www.idpf.org/2007/opf',
        'xmlns:dc'  => 'http://purl.org/dc/elements/1.1/',
        'xmlns:opf' => 'http://www.idpf.org/2007/opf',
      }.freeze

      EPUB3_NAMESPACES = {
        'prefix'     => 'rendition: http://www.idpf.org/vocab/rendition/',
        'xmlns:epub' => 'http://www.idpf.org/2007/ops',
      }.freeze

      IBOOKS_NAMESPACES = {
        'prefix'       => 'rendition: http://www.idpf.org/vocab/rendition/# ibooks: http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0/',
        'xmlns:ibooks' => 'http://apple.com/ibooks/html-extensions',
      }.freeze

      # resource page http://www.idpf.org/epub/20/spec/OPF_2.0.1_draft.htm#TOC2.6
      LANDMARKS_MAP = {

        # my favorite
        landmark_cover:      'cover',
        landmark_start_page: 'text',
        landmark_copyright:  'copyright-page',
        landmark_toc:        'toc',

        # others
        landmark_title:                 'title-page',
        landmark_index:                 'index',
        landmark_glossary:              'glossary',
        landmark_acknowledgements:      'acknowledgements',
        landmark_bibliography:          'bibliography',
        landmark_colophon:              'colophon',
        landmark_dedication:            'dedication',
        landmark_epigraph:              'epigraph',
        landmark_foreword:              'foreword',
        landmark_list_of_illustrations: 'loi',
        landmark_list_of_tables:        'lot',
        landmark_notes:                 'notes',
        landmark_preface:               'preface',

      }.freeze

      PROPERTIES_MAP = {
        cover_image: 'cover-image',
        navigation:  'nav',
        scripted:    'scripted',
      }.freeze

      OPF_UNIQUE_ID = 'bookid'

      # Generates XML for opf document
      #
      # Use method #to_s to generate nice string from XML document
      #
      # @return [Nokogiri::XML::Document]
      #
      def generate_opf
        generate_xml do |xml|
          xml.package(package_namespaces, :version => @target.epub_version, 'unique-identifier' => OPF_UNIQUE_ID) do
            generate_metadata
            generate_manifest
            generate_spine
            generate_guide
          end
        end
      end

      private

      # --------- METADATA --------------------------

      # @return nil
      #
      def generate_metadata
        epub_version = @target.epub_version

        @xml.metadata do
          # identifier
          identifier = @target.identifier || "urn:isbn:#{@target.isbn}"
          @xml['dc'].identifier(identifier, id: OPF_UNIQUE_ID)

          # title
          if @book.title
            if epub_version >= 3
              @xml['dc'].title(@book.title, id: 'title')
              @xml.meta('main', refines: '#title', property: 'title-type')
            else
              @xml['dc'].title(@book.title)
            end
          end

          # authors
          authors = @book.authors || []
          authors.each_with_index do |author, idx|
            author_id     = "author_#{idx + 1}"
            author_id_ref = "##{author_id}"

            if epub_version >= 3
              @xml['dc'].creator(author.pretty_name, id: author_id)
              @xml.meta(author.file_as, property: 'file-as', refines: author_id_ref)
              @xml.meta(author.role, property: 'role', refines: author_id_ref, scheme: 'marc:relators')
            else
              @xml['dc'].creator(author.pretty_name, 'opf:file-as' => author.file_as, 'opf:role' => author.role)
            end
          end

          @xml['dc'].publisher(@book.publisher) unless @book.publisher.nil?
          @xml['dc'].language(@book.language) unless @book.language.nil?
          @xml['dc'].date(@book.published.iso8601) unless @book.published.nil?

          cover_image = @target.cover_image
          unless cover_image.nil?
            cover_image_result = @file_resolver.file_from_request(cover_image)
            @xml.meta(name: 'cover', content: create_id_from_path(pretty_path(cover_image_result)))
          end

          if epub_version >= 3
            @xml.meta(Time.now.utc.iso8601, property: 'dcterms:modified')

            if @target.fixed_layout
              @xml.meta('pre-paginated', property: 'rendition:layout')
              @xml.meta('auto', property: 'rendition:orientation')
              @xml.meta('auto', property: 'rendition:spread')
            end

            if @target.ibooks?
              @xml.meta(@book.version, property: 'ibooks:version') unless @book.version.nil?
              @xml.meta(@target.custom_fonts, property: 'ibooks:specified-fonts') unless @target.custom_fonts.nil?
            end
          end

          @xml.meta(name: 'Created by', content: Epuber.to_s)
          @xml.meta(name: 'Epuber version', content: Epuber::VERSION)
        end
      end

      # --------- MANIFEST --------------------------

      # @return nil
      #
      def generate_manifest
        @xml.manifest do
          @file_resolver.manifest_files.each do |file|
            pretty_path         = pretty_path(file)
            attrs               = {}
            attrs['id']         = create_id_from_path(pretty_path)
            attrs['href']       = pretty_path
            attrs['media-type'] = mime_type_for(file)

            properties = file.properties
            if properties.length > 0 && @target.epub_version >= 3
              pretty_properties = properties.to_a.map { |property| PROPERTIES_MAP[property] }.join(' ')
              attrs['properties'] = pretty_properties
            end

            @xml.item(attrs)
          end
        end
      end

      # --------- SPINE --------------------------

      # @return nil
      #
      def generate_spine
        args = if @target.epub_version >= 3
                 {}
               else
                 nav_file = @file_resolver.manifest_files.find { |file| file.destination_path.end_with?('.ncx') }
                 raise 'not found nav file' if nav_file.nil?

                 { toc: create_id_from_path(pretty_path(nav_file)) }
               end

        all_items = @target.root_toc.flat_sub_items.map do |toc_item|
          result_file = @file_resolver.file_from_request(toc_item.file_request)

          attrs = {}
          attrs['idref'] = create_id_from_path(pretty_path(result_file))
          attrs['linear'] = 'no' unless toc_item.linear?

          attrs
        end

        # uniq, but without any other attributes
        all_items.uniq! { |i| i['idref'] }

        @xml.spine(args) do
          all_items.each do |attrs|
            @xml.itemref(attrs)
          end
        end
      end

      # --------- GUIDE --------------------------

      def generate_guide
        return if @target.epub_version >= 3

        @xml.guide do
          guide_visit_toc_item(@target.root_toc)
        end
      end

      # @param toc_items [Array<Epuber::Book::TocItem>]
      #
      # @return nil
      #
      def guide_visit_toc_items(toc_items)
        toc_items.each do |child_item|
          guide_visit_toc_item(child_item)
        end
      end

      # @param toc_item [Epuber::Book::TocItem]
      #
      # @return nil
      #
      def guide_visit_toc_item(toc_item)
        unless toc_item.file_request.nil?
          result_file = @file_resolver.file_from_request(toc_item.file_request)

          toc_item.landmarks.each do |landmark|
            type = LANDMARKS_MAP[landmark]

            raise "Unknown landmark `#{landmark.inspect}`, supported are #{LANDMARKS_MAP.keys}" if type.nil?

            @xml.reference(type: type, href: pretty_path(result_file))
          end
        end

        guide_visit_toc_items(toc_item.sub_items)
      end

      # --------- other methods --------------------------

      # Creates id from file path
      #
      # @param path [String]
      #
      # @return [String]
      #
      def create_id_from_path(path)
        path && path.gsub('/', '.')
      end

      # Creates proper mime-type for file
      #
      # @param file [Epuber::Book::File]
      #
      # @return [String]
      #
      def mime_type_for(file)
        filename = file.destination_path
        MIME::Types.of(filename).first.content_type
      end

      # Creates hash of namespaces for root package element
      #
      # @return [Hash<String, String>]
      #
      def package_namespaces
        namespaces = [EPUB2_NAMESPACES]
        namespaces << EPUB3_NAMESPACES if @target.epub_version >= 3
        namespaces << IBOOKS_NAMESPACES if @target.epub_version >= 3 && @target.ibooks?
        namespaces.reduce(:merge)
      end
    end
  end
end
