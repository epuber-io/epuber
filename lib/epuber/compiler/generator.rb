# encoding: utf-8

require 'nokogiri'

module Epuber
  class Compiler
    class Generator
      # @return [Epuber::Compiler::CompilationContext]
      #
      attr_reader :compilation_context

      # @param [Epuber::Compiler::CompilationContext] compilation_context
      #
      def initialize(compilation_context)
        @compilation_context = compilation_context
        @book = compilation_context.book
        @target = compilation_context.target
        @file_resolver = compilation_context.file_resolver
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
