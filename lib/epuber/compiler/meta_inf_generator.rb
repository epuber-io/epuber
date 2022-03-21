# frozen_string_literal: true

require 'mime-types'

require_relative 'generator'
require_relative '../book/file_request'


module Epuber
  class Compiler
    class MetaInfGenerator < Generator
      # @return [Nokogiri::XML::Document]
      #
      def generate_container_xml
        generate_xml do |xml|
          xml.container(version: 1.0, xmlns: 'urn:oasis:names:tc:opendocument:xmlns:container') do
            xml.rootfiles do
              @file_resolver.package_files.select { |file| file.kind_of?(FileTypes::OPFFile) }.each do |file|
                path = file.pkg_destination_path
                xml.rootfile('full-path' => path, 'media-type' => MIME::Types.of(path).first.content_type)
              end
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
    end
  end
end
