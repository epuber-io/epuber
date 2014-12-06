require 'nokogiri/xml/builder'

module Epuber
  class MainController

    EPUB2_NAMESPACES = {
      'xmlns' => 'http://www.idpf.org/2007/opf',
      'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
    }.freeze

    EPUB3_NAMESPACES = {
      'xmlns:epub' => 'http://www.idpf.org/2007/ops',
    }.freeze

    IBOOKS_NAMESPACES = {
      'prefix' => 'rendition: http://www.idpf.org/vocab/rendition/# ibooks: http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0/',
      'xmlns:ibooks' => 'http://apple.com/ibooks/html-extensions',
    }.freeze

    OPF_UNIQUE_ID = 'bookid'


    def generate_opf
      book = self.book

      builder = Nokogiri::XML::Builder.new(encoding: 'utf-8') { |xml|
        package_namespaces = EPUB2_NAMESPACES.merge(EPUB3_NAMESPACES)
        xml.package(package_namespaces, :version => book.epub_version, 'unique-identifier' => OPF_UNIQUE_ID) {
          xml.metadata {
            xml['dc'].title book.title if book.title
          }
          xml.manifest
          xml.spine
        }
      }

      builder.to_xml
    end
  end
end
