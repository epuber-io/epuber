require 'time'

require 'nokogiri'
require 'mime-types'


module Epuber
  class MainController
    module OPF

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

      # @param path [String]
      # @return [String]
      #
      def create_id_from_path(path)
        path && path.gsub('/', '.')
      end

      # @param file [Epuber::Book::File]
      # @return [String]
      #
      def mime_type_for(file)
        filename = file.destination_path
        MIME::Types.of(filename).first.content_type
      end

      # @param target [Epuber::Book::Target]
      # @param book [Epuber::Book::Book]
      #
      def generate_opf(book, target)
        epub_version = target.epub_version

        builder = Nokogiri::XML::Builder.new(encoding: 'utf-8') { |xml|
          package_namespaces = if epub_version >= 3
                                 EPUB2_NAMESPACES.merge(EPUB3_NAMESPACES)
                               else
                                 EPUB2_NAMESPACES
                               end
          
          xml.package(package_namespaces, :version => epub_version, 'unique-identifier' => OPF_UNIQUE_ID) {
            xml.metadata {
              if book.title
                if epub_version >= 3
                  xml['dc'].title(book.title, id: 'title')
                  xml.meta('main', refines: '#title', property: 'title-type')
                else
                  xml['dc'].title(book.title)
                end
              end

              authors = book.authors || []
              authors.each_index { |idx|
                author        = authors[idx]
                author_id     = "author_#{idx + 1}"
                author_id_ref = "##{author_id}"

                if epub_version >= 3
                  xml['dc'].creator(author.pretty_name, id: author_id)
                  xml.meta(author.file_as, property: 'file-as', refines: author_id_ref)
                  xml.meta(author.role, property: 'role', refines: author_id_ref, scheme: 'marc:relators')
                else
                  xml['dc'].creator(author.pretty_name)
                end
              }

              xml['dc'].publisher(book.publisher) unless book.publisher.nil?
              xml['dc'].language(book.language) unless book.language.nil?
              xml['dc'].date(book.published.iso8601) unless book.published.nil?

              xml.meta(name: 'cover', content: create_id_from_path(target.cover_image.destination_path)) unless target.cover_image.nil?

              if epub_version >= 3
                xml.meta(Time.now.utc.iso8601, property: 'dcterms:modified')

                if target.is_ibooks
                  xml.meta(book.version, property: 'ibooks:version') unless book.version.nil?
                  xml.meta(book.custom_fonts, property: 'ibooks:specified-fonts') unless book.custom_fonts.nil?
                end
              end
            }
            xml.manifest {
              target.all_files.each { |file|
                xml.item(id: create_id_from_path(file.destination_path), href: file.destination_path, 'media-type' => mime_type_for(file))
              }
            }
            xml.spine
          }
        }

        builder.doc
      end

      # @param target [Epuber::Book::Target]
      # @param book [Epuber::Book::Book]
      # @return [Epuber::Book::File]
      #
      def generate_opf_file(book, target)
        opf_file = Epuber::Book::File.new(nil)
        opf_file.destination_path = 'content.opf'
        opf_file.content = generate_opf(book, target)
        opf_file
      end
    end
  end
end
