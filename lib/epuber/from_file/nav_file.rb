# frozen_string_literal: true

module Epuber
  class NavFile
    class NavItem
      # @return [String]
      attr_accessor :href
      # @return [String]
      attr_accessor :title
      # @return [Array<NavItem>]
      attr_accessor :children

      # @param [String] href
      # @param [String] title
      #
      def initialize(href, title)
        @href = href
        @title = title
        @children = []
      end

      # @param [String] other_href
      # @param [Boolean] ignore_fragment
      #
      # @return [NavItem, nil]
      #
      def find_by_href(other_href, ignore_fragment: false)
        if ignore_fragment
          other_href = other_href.split('#').first
          self_href = @href.split('#').first
          return self if self_href == other_href
        elsif @href == other_href
          return self
        end

        @children.find { |item| item.find_by_href(other_href) }
      end
    end

    class LandmarkItem
      # @return [String]
      #
      attr_accessor :href

      # @return [String]
      #
      attr_accessor :type

      # @param [String] href
      # @param [String] type
      #
      def initialize(href, type)
        @href = href
        @type = type
      end

      # @param [Nokogiri::XML::Node] node
      #
      # @return [LandmarkItem]
      #
      def self.from_node(node)
        new(node['href'], node['type'])
      end
    end

    LANDMARKS_MAP = {
      'cover' => :landmark_cover,
      'bodymatter' => :landmark_start_page,
      'copyright-page' => :landmark_copyright,
      'toc' => :landmark_toc,
    }.freeze

    MODE_NCX = :ncx
    MODE_XHTML = :xhtml

    # @return [Nokogiri::XML::Document]
    #
    attr_reader :document

    # @return [:ncx, :xhtml]
    #
    attr_reader :mode

    # @return [Array<NavItem>]
    #
    attr_reader :items

    # @return [Array<LandmarkItem>, nil]
    #
    attr_reader :landmarks

    # @param [string] document
    # @param [:ncx, :xhtml] mode
    #
    def initialize(document, mode)
      raise ArgumentError, 'mode must be :ncx or :xhtml' unless [MODE_NCX, MODE_XHTML].include?(mode)

      @document = Nokogiri::XML(document)
      @document.remove_namespaces!

      @mode = mode
      @items = _parse

      @landmarks = _parse_landmarks
    end

    # @param [String] href
    # @param [Boolean] ignore_fragment
    #
    # @return [NavItem, nil]
    #
    def find_by_href(href, ignore_fragment: false)
      @items.find { |item| item.find_by_href(href, ignore_fragment: ignore_fragment) }
    end

    private

    # @param [Nokogiri::XML::Element] li_node
    #
    # @return [NavItem]
    #
    def _parse_nav_xhtml_item(li_node)
      href = li_node.at_css('a')['href'].strip
      title = li_node.at_css('a').text.strip

      item = NavItem.new(href, title)
      item.children = li_node.css('ol > li').map { |p| _parse_nav_xhtml_item(p) }
      item
    end

    # @param [Nokogiri::XML::Element] point_node
    #
    # @return [NavItem]
    #
    def _parse_nav_ncx_item(point_node)
      href = point_node.at_css('content')['src'].strip
      title = point_node.at_css('navLabel text').text.strip

      item = NavItem.new(href, title)
      item.children = point_node.css('> navPoint').map { |p| _parse_nav_ncx_item(p) }
      item
    end

    # @return [Array<NavItem>]
    #
    def _parse
      if @mode == MODE_XHTML
        @document.css('nav[type="toc"] > ol > li')
                 .map { |point| _parse_nav_xhtml_item(point) }
      elsif @mode == MODE_NCX
        @document.css('navMap > navPoint')
                 .map { |point| _parse_nav_ncx_item(point) }
      end
    end

    def _parse_landmarks
      return nil if @mode != MODE_XHTML

      @document.css('nav[type="landmarks"] > ol > li > a')
               .map { |node| LandmarkItem.from_node(node) }
    end
  end
end
