require 'time'

require 'nokogiri/xml/builder'


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


      # @param target [Target]
      #
      def generate_opf(target = nil)
        book = self.book

        target ||= if book.targets.count == 1
                     book.targets.first
                   else
                     raise 'Please specify target, can take first target only when there is only one target'
                   end

        epub_version = target.epub_version


        builder = Nokogiri::XML::Builder.new(encoding: 'utf-8') { |xml|
          package_namespaces = EPUB2_NAMESPACES.merge(EPUB3_NAMESPACES)
          xml.package(package_namespaces, :version => book.epub_version, 'unique-identifier' => OPF_UNIQUE_ID) {
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
                  xml.meta('aut', property: 'role', refines: author_id_ref, scheme: 'marc:relators')
                else
                  xml['dc'].creator(author.pretty_name)
                end
              }

              xml['dc'].publisher(book.publisher) unless book.publisher.nil?
              xml['dc'].language(book.language) unless book.language.nil?
              xml['dc'].date(book.published.iso8601) unless book.published.nil?

              if epub_version >= 3
                xml.meta(Time.now.utc.iso8601, property: 'dcterms:modified')

                if epub_version >= 3 && target.is_ibooks
                  xml.meta(book.version, property: 'ibooks:version') unless book.version.nil?
                  xml.meta(book.custom_fonts, property: 'ibooks:specified-fonts') unless book.custom_fonts.nil?
                end
              end
            }
            xml.manifest
            xml.spine
          }
        }

        builder.doc
      end
    end
  end
end
