require 'nokogiri'

module Epuber
  class MainController
    class Generator

      protected

      # Helper function for generating XML
      # @param block
      # @return [Nokogiri::XML::Document]
      #
      def generate_xml(&block)
        builder = Nokogiri::XML::Builder.new(encoding: 'utf-8') { |xml|
          @xml = xml

          yield xml if block_given?

          @xml = nil
        }
        builder.doc
      end

    end
  end
end
