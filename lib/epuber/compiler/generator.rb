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

      # @param [Epuber::Book::FileRequest] file_request
      #
      # @return [String]
      #
      def pretty_path_for_request(file_request, fragment: true)
        file = @file_resolver.file_from_request(file_request)
        path = file.destination_path

        if fragment
          pattern = file_request.source_pattern
          fragment_index = pattern.index('#')
          unless fragment_index.nil?
            path += pattern[fragment_index..-1]
          end
        end

        path
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
