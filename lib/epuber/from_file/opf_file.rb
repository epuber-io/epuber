# frozen_string_literal: true

module Epuber
  class OpfFile
    class SpineItem
      # @return [String]
      #
      attr_accessor :idref

      # @return [String]
      #
      attr_accessor :linear

      def initialize(idref, linear)
        @idref = idref
        @linear = linear
      end

      # @param [SpineItem] other
      #
      # @return [Boolean]
      #
      def ==(other)
        @idref == other.idref
      end

      # @param [Nokogiri::XML::Node] node
      #
      # @return [SpineItem]
      #
      def self.from_node(node)
        new(node['idref'], node['linear'])
      end
    end

    # @return [Nokogiri::XML::Document]
    #
    attr_reader :document

    # @return [Nokogiri::XML::Node, nil]
    #
    attr_reader :package, :metadata, :manifest, :spine

    # @return [Array<SpineItem>]
    #
    attr_reader :spine_items

    # @param [String] document
    def initialize(xml)
      @document = Nokogiri::XML(xml)
      @document.remove_namespaces!

      @package = @document.at_css('package')
      @metadata = @document.at_css('package metadata')
      @manifest = @document.at_css('package manifest')
      @spine = @document.at_css('package spine')

      @spine_items = @document.css('package spine itemref').map { |node| SpineItem.from_node(node) }
    end

    # @param opf [Nokogiri::XML::Document]
    #
    # @return [Array<Nokogiri::XML::Document, Nokogiri::XML::Document>] nav, ncx
    #
    def find_nav_and_ncx
      nav = manifest.at_css('item[properties="nav"]')

      ncx_id = @spine['toc'] if @spine
      ncx = manifest_file_by_id(ncx_id) if ncx_id

      [nav, ncx]
    end

    def find_refines(id, property)
      @metadata.at_css(%(meta[refines="##{id}"][property="#{property}"]))&.text
    end

    # @param [String] id
    #
    # @return [Nokogiri::XML::Element]
    #
    def manifest_file_by_id(id)
      node = @manifest.at_css(%(item[id="#{id}"]))
      raise "Manifest item with id #{id.inspect} not found" unless node

      node
    end

    def manifest_file_by_href(href)
      # remove anchor
      href = href.sub(/#.*$/, '')

      node = @manifest.at_css(%(item[href="#{href}"]))
      raise "Manifest item with href #{href.inspect} not found" unless node

      node
    end
  end
end
