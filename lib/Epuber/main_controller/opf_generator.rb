require 'time'

require 'nokogiri'
require 'mime-types'

require_relative '../book/toc_item'


module Epuber
  class MainController
    class OPFGenerator

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
        builder = Nokogiri::XML::Builder.new(encoding: 'utf-8') { |xml|
          @xml = xml

          xml.package(package_namespaces, :version => @target.epub_version, 'unique-identifier' => OPF_UNIQUE_ID) {
            generate_metadata
            generate_manifest
            generate_spine
          }

          @xml = nil
        }

        builder.doc
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

        @xml.metadata {

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
          authors.each_index { |idx|
            author        = authors[idx]
            author_id     = "author_#{idx + 1}"
            author_id_ref = "##{author_id}"

            if epub_version >= 3
              @xml['dc'].creator(author.pretty_name, id: author_id)
              @xml.meta(author.file_as, property: 'file-as', refines: author_id_ref)
              @xml.meta(author.role, property: 'role', refines: author_id_ref, scheme: 'marc:relators')
            else
              @xml['dc'].creator(author.pretty_name)
            end
          }

          @xml['dc'].publisher(@book.publisher) unless @book.publisher.nil?
          @xml['dc'].language(@book.language) unless @book.language.nil?
          @xml['dc'].date(@book.published.iso8601) unless @book.published.nil?

          @xml.meta(name: 'cover', content: create_id_from_path(@target.cover_image.destination_path)) unless @target.cover_image.nil?

          if epub_version >= 3
            @xml.meta(Time.now.utc.iso8601, property: 'dcterms:modified')

            if @target.is_ibooks
              @xml.meta(@book.version, property: 'ibooks:version') unless @book.version.nil?
              @xml.meta(@book.custom_fonts, property: 'ibooks:specified-fonts') unless @book.custom_fonts.nil?
            end
          end
        }
      end

      # --------- MANIFEST --------------------------

      def generate_manifest
        @xml.manifest {
          all_files = @target.all_files
          all_files.each { |file|
            attrs = {}
            attrs['id'] = create_id_from_path(file.destination_path)
            attrs['href'] = file.destination_path
            attrs['media-type'] = mime_type_for(file)
            attrs['properties'] = file.properties.to_a.join(' ') if file.properties.length > 0 && @target.epub_version >= 3

            @xml.item(attrs)
          }
        }
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

        @xml.spine(args) {
          visit_toc_items(@book.root_toc.child_items)
        }
      end

      # @param toc_items [Array<Epuber::Book::TocItem>]
      #
      def visit_toc_items(toc_items)
        toc_items.each { |child_item|
          visit_toc_item(child_item)
        }
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
        namespaces = [ EPUB2_NAMESPACES ]
        namespaces << EPUB3_NAMESPACES if @target.epub_version >= 3
        namespaces << IBOOKS_NAMESPACES if @target.epub_version >= 3 && @target.is_ibooks?
        namespaces.reduce(:merge)
      end
    end
  end
end
