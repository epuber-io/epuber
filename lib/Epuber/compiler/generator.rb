# encoding: utf-8

require 'nokogiri'

module Epuber
  class Compiler
    class Generator
      protected

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
