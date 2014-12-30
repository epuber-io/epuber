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
        builder = Nokogiri::XML::Builder.new(encoding: 'utf-8') { |xml|
          @xml = xml

          block.call(xml) unless block.nil?

          @xml = nil
        }
        builder.doc
      end

    end
  end
end
