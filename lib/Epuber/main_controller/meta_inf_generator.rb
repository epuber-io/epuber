
require 'nokogiri'
require 'mime-types'

require_relative '../book/file'

module Epuber
  class MainController
    class MetaInfGenerator

      # @param book [Epuber::Book::Book]
      # @param target [Epuber::Book::Target]
      # @param content_opf_path [String]
      #
      def initialize(book, target, content_opf_path)
        @book = book
        @target = target
        @content_opf_path = content_opf_path
      end

      # @return [Nokogiri::XML::Document]
      #
      def generate_container_xml
        builder = Nokogiri::XML::Builder.new(encoding: 'utf-8') { |xml|
          xml.container(version: 1.0, xmlns: 'urn:oasis:names:tc:opendocument:xmlns:container') {
            xml.rootfiles {
              xml.rootfile('full-path' => @content_opf_path, 'media-type' => MIME::Types.of(@content_opf_path).first.content_type)
            }
          }
        }
        builder.doc
      end

      # @return [Array<Epuber::Book::File>]
      #
      def generate_all_files
        container_xml = Epuber::Book::File.new(nil)
        container_xml.destination_path = '../META-INF/container.xml'
        container_xml.content = generate_container_xml

        [ container_xml ]
      end
    end
  end
end
