# encoding: utf-8

require 'nokogiri'

module Epuber
  class Compiler
    class Generator

      # @param target [Epuber::Book::Target]
      # @param book [Epuber::Book::Book]
      # @param file_resolver [FileResolver]
      #
      def initialize(book, target, file_resolver)
        @book = book
        @target = target
        @file_resolver = file_resolver
      end

      protected

      # @param file [Epuber::Compiler::File]
      #
      def pretty_path(file)
        base_path = ::File.join(@file_resolver.destination_path, Epuber::Compiler::EPUB_CONTENT_FOLDER, '')
        file.destination_path.sub(base_path, '')
      end

      # Helper function for generating XML
      # @param block
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
