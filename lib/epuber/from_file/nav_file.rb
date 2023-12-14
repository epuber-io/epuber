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

      # @param [String] href
      #
      # @return [NavItem, nil]
      #
      def find_by_href(href)
        return self if @href == href

        @children.find { |item| item.find_by_href(href) }
      end
    end

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

    # @param [string] document
    # @param [:ncx, :xhtml] mode
    #
    def initialize(document, mode)
      raise ArgumentError, 'mode must be :ncx or :xhtml' unless [MODE_NCX, MODE_XHTML].include?(mode)

      @document = Nokogiri::XML(document)
      @document.remove_namespaces!

      @mode = mode
      @items = _parse
    end

    # @param [String] href
    #
    # @return [NavItem, nil]
    #
    def find_by_href(href)
      @items.find { |item| item.find_by_href(href) }
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
  end
end
