# encoding: utf-8

require 'mime-types'

require_relative 'generator'
require_relative '../book/file_request'


module Epuber
  class Compiler
    class MetaInfGenerator < Generator
      # @param [Epuber::Book::Book] book
      # @param [Epuber::Book::Target] target
      # @param [String] content_opf_path
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

      # @return nil
      #
      def generate_ibooks_display_options_xml
        generate_xml do |xml|
          xml.display_options do
            xml.platform(name: '*') do
              xml.option(true.to_s, name: 'specified-fonts') if @target.custom_fonts
              xml.option(true.to_s, name: 'fixed-layout') if @target.fixed_layout
            end
          end
        end
      end

      # @return [Array<Epuber::Compiler::File>]
      #
      def generate_all_files
        all = []

        container_xml                  = FileTypes::GeneratedFile.new
        container_xml.path_type        = :package
        container_xml.destination_path = 'META-INF/container.xml'
        container_xml.content          = generate_container_xml
        all << container_xml

        if @target.ibooks?
          display_options                  = FileTypes::GeneratedFile.new
          display_options.path_type        = :package
          display_options.destination_path = 'META-INF/com.apple.ibooks.display-options.xml'
          display_options.content          = generate_ibooks_display_options_xml
          all << display_options
        end

        all
      end
    end
  end
end
