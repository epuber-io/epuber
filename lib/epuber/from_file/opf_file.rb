# frozen_string_literal: true

module Epuber
  class OpfFile
    class ManifestItem
      # @return [String]
      #
      attr_accessor :id

      # @return [String]
      #
      attr_accessor :href

      # @return [String]
      #
      attr_accessor :media_type

      # @return [String, nil]
      #
      attr_accessor :properties

      def initialize(id, href, media_type, properties)
        @id = id
        @href = href
        @media_type = media_type
        @properties = properties
      end

      # @param [ManifestItem] other
      #
      # @return [Boolean]
      #
      def ==(other)
        @id == other.id
      end

      # @param [Nokogiri::XML::Node] node
      #
      # @return [ManifestItem]
      #
      def self.from_node(node)
        new(node['id'], node['href'], node['media-type'], node['properties'])
      end
    end

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

    class GuideItem
      # @return [String]
      #
      attr_accessor :type

      # @return [String]
      #
      attr_accessor :href

      def initialize(type, href)
        @type = type
        @href = href
      end

      # @param [Nokogiri::XML::Node] node
      #
      # @return [GuideItem]
      #
      def self.from_node(node)
        new(node['type'], node['href'])
      end
    end

    # reversed map of generator's map
    LANDMARKS_MAP = Compiler::OPFGenerator::LANDMARKS_MAP.map { |k, v| [v, k] }
                                                         .to_h
                                                         .freeze

    # @return [Nokogiri::XML::Document]
    #
    attr_reader :document

    # @return [Nokogiri::XML::Node, nil]
    #
    attr_reader :package, :metadata, :manifest, :spine

    # @return [Hash<String, ManifestItem>]
    #
    attr_reader :manifest_items

    # @return [Array<SpineItem>]
    #
    attr_reader :spine_items

    # @return [Array<GuideItem>]
    #
    attr_reader :guide_items

    # @param [String] document
    def initialize(xml)
      @document = Nokogiri::XML(xml)
      @document.remove_namespaces!

      @package = @document.at_css('package')
      @metadata = @document.at_css('package metadata')
      @manifest = @document.at_css('package manifest')
      @spine = @document.at_css('package spine')

      @manifest_items = @document.css('package manifest item')
                                 .map { |node| ManifestItem.from_node(node) }
                                 .map { |item| [item.id, item] }
                                 .to_h
      @spine_items = @document.css('package spine itemref')
                              .map { |node| SpineItem.from_node(node) }
      @guide_items = @document.css('package guide reference')
                              .map { |node| GuideItem.from_node(node) }
    end

    # Find nav file in EPUB (both EPUB 2 and EPUB 3). Returns array with nav and type of nav (:xhtml or :ncx).
    #
    # @return [Array<ManifestItem, [:ncx, :xhtml]>, nil] nav, ncx
    #
    def find_nav
      nav = @manifest_items.find { |_, item| item.properties == 'nav' }&.last
      return [nav, NavFile::MODE_XHTML] if nav

      ncx_id = @spine['toc'] if @spine
      ncx = manifest_file_by_id(ncx_id) if ncx_id
      return [ncx, NavFile::MODE_NCX] if ncx

      nil
    end

    # Find meta refines in EPUB 3 metadata
    #
    # @param [String] id
    # @param [String] property
    #
    # @return [String, nil]
    #
    def find_refines(id, property)
      @metadata.at_css(%(meta[refines="##{id}"][property="#{property}"]))&.text
    end

    # Find file in <manifest> by id. Throws exception when not found.
    #
    # @param [String] id
    #
    # @return [ManifestItem]
    #
    def manifest_file_by_id(id)
      item = @manifest_items[id]
      raise "Manifest item with id #{id.inspect} not found" unless item

      item
    end

    # Find file in <manifest> by href. Throws exception when not found.
    #
    # @param [String] href
    #
    # @return [ManifestItem]
    #
    def manifest_file_by_href(href)
      # remove anchor
      href = href.sub(/#.*$/, '')

      item = @manifest_items.find { |_, i| i.href == href }&.last
      raise "Manifest item with href #{href.inspect} not found" unless item

      item
    end
  end
end
