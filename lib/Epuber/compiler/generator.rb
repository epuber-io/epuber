# encoding: utf-8

require 'nokogiri'

module Epuber
  class Compiler
    class Generator
      # @param [Epuber::Book::Target] target
      # @param [Epuber::Book::Book] book
      # @param [FileResolver] file_resolver
      #
      def initialize(book, target, file_resolver)
        @book = book
        @target = target
        @file_resolver = file_resolver
      end

      protected

      # @param file [Epuber::Compiler::File]
      #
      # @return [String]
      #
      def pretty_path(file)
        base_path = ::File.join(@file_resolver.destination_path, Epuber::Compiler::EPUB_CONTENT_FOLDER, '')
        file.destination_path.sub(base_path, '')
      end

      # Helper function for generating XML
      #
      # @yields xml_builder
      # @yieldsparam [Nokogiri::XML::Builder] xml_builder
      #
      # @return [Nokogiri::XML::Document]
      #
      def generate_xml(&block)
        builder = Nokogiri::XML::Builder.new(encoding: 'utf-8') do |xml|
          @xml = xml

          block.call(xml) unless block.nil?

          @xml = nil
        end

        builder.doc
      end
    end
  end
end
