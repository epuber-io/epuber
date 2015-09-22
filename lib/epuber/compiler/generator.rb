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

      def pretty_path_for_toc_item(toc_item, fragment: true)
        file = @file_resolver.file_from_request(toc_item.file_request)
        [file.destination_path, fragment ? toc_item.file_fragment : nil].compact.join('#')
      end

      # @param [Epuber::Compiler::FileTypes::AbstractFile] file
      #
      # @return [String]
      #
      def pretty_path(file)
        file.destination_path
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
