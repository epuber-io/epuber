# encoding: utf-8

require 'mime-types'

require_relative 'generator'
require_relative '../book/file'


module Epuber
  class Compiler
    class MetaInfGenerator < Generator
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
        generate_xml do |xml|
          xml.container(version: 1.0, xmlns: 'urn:oasis:names:tc:opendocument:xmlns:container') do
            xml.rootfiles do
              path = @content_opf_path
              xml.rootfile('full-path' => path, 'media-type' => MIME::Types.of(path).first.content_type)
            end
          end
        end
      end

      def generate_ibooks_display_options_xml
        generate_xml do |xml|
          xml.display_options do
            xml.platform(name: '*') do
              xml.option(true.to_s, name: 'specified-fonts')
            end
          end
        end
      end

      # @return [Array<Epuber::Book::File>]
      #
      def generate_all_files
        all = []
        container_xml = Epuber::Book::File.new(nil)
        container_xml.destination_path = '../META-INF/container.xml'
        container_xml.content = generate_container_xml
        all << container_xml

        if @target.custom_fonts && @target.is_ibooks?
          display_options = Epuber::Book::File.new(nil)
          display_options.destination_path = '../META-INF/com.apple.ibooks.display-options.xml'
          display_options.content = generate_ibooks_display_options_xml
          all << display_options
        end

        all
      end
    end
  end
end
