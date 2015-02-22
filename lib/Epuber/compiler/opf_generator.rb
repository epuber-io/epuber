# encoding: utf-8

require 'time'

require 'mime-types'

require_relative 'generator'
require_relative '../book/toc_item'


module Epuber
  class Compiler
    class OPFGenerator < Generator
      EPUB2_NAMESPACES = {
        'xmlns'    => 'http://www.idpf.org/2007/opf',
        'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
      }.freeze

      EPUB3_NAMESPACES = {
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

      OPF_UNIQUE_ID = 'bookid'

      # @param target [Epuber::Book::Target]
      # @param book [Epuber::Book::Book]
      #
      def initialize(book, target)
        @book = book
        @target = target
      end

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

      # @return [Epuber::Book::File]
      #
      def generate_opf_file
        opf_file = Epuber::Book::File.new(nil)
        opf_file.destination_path = 'content.opf'
        opf_file.content = generate_opf
        opf_file
      end


      private

      # --------- METADATA --------------------------

      def generate_metadata
        epub_version = @target.epub_version

        @xml.metadata do
          # identifier
          @xml['dc'].identifier("urn:isbn:#{@target.isbn}", id: OPF_UNIQUE_ID)

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
              @xml['dc'].creator(author.pretty_name)
            end
          end

          @xml['dc'].publisher(@book.publisher) unless @book.publisher.nil?
          @xml['dc'].language(@book.language) unless @book.language.nil?
          @xml['dc'].date(@book.published.iso8601) unless @book.published.nil?

          cover_image = @target.cover_image
          @xml.meta(name: 'cover', content: create_id_from_path(cover_image.destination_path)) unless cover_image.nil?

          if epub_version >= 3
            @xml.meta(Time.now.utc.iso8601, property: 'dcterms:modified')

            if @target.ibooks?
              @xml.meta(@book.version, property: 'ibooks:version') unless @book.version.nil?
              @xml.meta(@book.custom_fonts, property: 'ibooks:specified-fonts') unless @book.custom_fonts.nil?
            end
          end

          @xml.meta(name: 'Created by', content: Epuber.to_s)
          @xml.meta(name: 'Epuber version', content: Epuber::VERSION)
        end
      end

      # --------- MANIFEST --------------------------

      def generate_manifest
        @xml.manifest do
          @target.all_files.each do |file|
            attrs               = {}
            attrs['id']         = create_id_from_path(file.destination_path)
            attrs['href']       = file.destination_path
            attrs['media-type'] = mime_type_for(file)

            properties          = file.properties
            attrs['properties'] = properties.to_a.join(' ') if properties.length > 0 && @target.epub_version >= 3

            @xml.item(attrs)
          end
        end
      end

      # --------- SPINE --------------------------

      def generate_spine
        args = if @target.epub_version >= 3
                 {}
               else
                 nav_file = @target.all_files.find { |file| file.destination_path.end_with?('.ncx') }
                 raise 'not found nav file' if nav_file.nil?

                 { toc: create_id_from_path(nav_file.destination_path) }
               end

        @xml.spine(args) do
          visit_toc_items(@target.root_toc.child_items)
        end
      end

      # @param toc_items [Array<Epuber::Book::TocItem>]
      #
      def visit_toc_items(toc_items)
        toc_items.each do |child_item|
          visit_toc_item(child_item)
        end
      end

      # @param toc_item [Epuber::Book::TocItem]
      #
      def visit_toc_item(toc_item)
        attrs = {}
        attrs['idref'] = create_id_from_path(toc_item.file_obj.destination_path)
        attrs['linear'] = 'no' unless toc_item.linear?

        @xml.itemref(attrs)

        visit_toc_items(toc_item.child_items)
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
      def guide_visit_toc_items(toc_items)
        toc_items.each do |child_item|
          guide_visit_toc_item(child_item)
        end
      end

      # @param toc_item [Epuber::Book::TocItem]
      #
      def guide_visit_toc_item(toc_item)
        toc_item.landmarks.each do |landmark|
          type = LANDMARKS_MAP[landmark]

          raise "Unknown landmark `#{landmark.inspect}`, supported are #{LANDMARKS_MAP}" if type.nil?

          @xml.reference(type: type, href: toc_item.file_obj.destination_path)
        end

        guide_visit_toc_items(toc_item.child_items)
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
        namespaces << IBOOKS_NAMESPACES if @target.epub_version >= 3 && @target.is_ibooks?
        namespaces.reduce(:merge)
      end
    end
  end
end
