# frozen_string_literal: true

module Epuber
  class BookspecGenerator
    class NavItem
      # @return [String]
      attr_accessor :href
      # @return [String]
      attr_accessor :title
      # @return [Array<NavItem>]
      attr_accessor :children

      def initialize(href, title)
        @href = href
        @title = title
        @children = []
      end
    end

    # @param opf [Nokogiri::XML::Document]
    #
    # @return [Array<Nokogiri::XML::Document, Nokogiri::XML::Document>] nav, ncx
    #
    def self.find_nav_and_ncx(opf)
      nav = opf.at_css('manifest item[properties="nav"]')

      spine = opf.at_css('spine')
      ncx_id = spine['toc']
      ncx = opf.at_css(%(manifest item[id="#{ncx_id}"]))

      [nav, ncx]
    end

    # @param opf [Nokogiri::XML::Document]
    # @param nav [Nokogiri::XML::Document, nil]
    # @param ncx [Nokogiri::XML::Document, nil]
    #
    def initialize(opf, nav: nil, ncx: nil)
      @opf = opf
      @opf.remove_namespaces!

      @nav_xhtml = nav
      @nav_xhtml&.remove_namespaces!
      @ncx = ncx
      @ncx&.remove_namespaces!
      @nav = _parse_nav

      @metadata = @opf.at_css('package metadata')
      @manifest = @opf.at_css('package manifest')
    end

    # @return [String]
    def generate_bookspec
      @indent = 0
      @bookspec = []

      add_code('Epuber::Book.new do |book|', after: 'end') do
        generate_titles
        generate_authors
        add_empty_line
        generate_id
        generate_language
        generate_published
        generate_publisher
        add_empty_line
        generate_toc
      end
      add_empty_line

      @bookspec.join("\n")
    end

    # @return [void]
    #
    def generate_titles
      titles = @metadata.css('title')
      titles.each do |title|
        is_main = titles.count == 1

        id = title['id']
        is_main = find_refines(id, 'title-type') == 'main' if id && !is_main

        add_comment('alternate title found from original EPUB file (Epuber supports only one title)') unless is_main
        add_setting_property(:title, title.text.inspect, commented: !is_main)
      end
    end

    # @return [void]
    #
    def generate_authors
      authors = @metadata.css('creator')
      if authors.empty?
        add_setting_property(:author, nil)
      elsif authors.count == 1
        add_setting_property(:author, format_author(authors.first))
      else
        add_setting_property(:authors, authors.map { |auth| format_author(auth) })
      end
    end

    # @return [String]
    #
    def format_author(author_node)
      name = author_node.text
      id = author_node['id']

      if id
        role = find_refines(id, 'role')
        file_as = find_refines(id, 'file-as')
      else
        role = author_node['role']
        file_as = author_node['file-as']
      end

      role_is_default = role.nil? || role == 'aut'
      file_as_is_default = file_as.nil? || contributor_file_as_eq?(Book::Contributor.from_obj(name).file_as, file_as)

      if role_is_default && file_as_is_default
        name.inspect
      elsif role_is_default && !file_as_is_default
        %({ pretty_name: #{name.inspect}, file_as: #{file_as.inspect} })
      elsif !role_is_default && file_as_is_default
        %({ name: #{name.inspect}, role: #{role.inspect} })
      else
        %({ pretty_name: #{name.inspect}, file_as: #{file_as.inspect}, role: #{role.inspect} })
      end
    end

    # @return [void]
    #
    def generate_id
      nodes = @metadata.css('identifier')

      nodes.each do |id_node|
        value = id_node.text

        is_main = @opf.at_css('package')['unique-identifier'] == id_node['id']
        is_isbn = value.start_with?('urn:isbn:')
        value = value.sub(/^urn:isbn:/, '').strip if is_isbn
        key = is_isbn ? :isbn : :identifier

        if is_main
          add_setting_property(key, value.inspect)
        else
          add_comment('alternate identifier found from original EPUB file (Epuber supports only one identifier)')
          add_setting_property(key, value.inspect, commented: true)
        end
      end
    end

    # @return [String]
    #
    def generate_language
      language = @metadata.at_css('language')
      add_setting_property(:language, language.text.strip.inspect) if language
    end

    # @return [String]
    #
    def generate_published
      published = @metadata.at_css('date')
      add_setting_property(:published, published.text.strip.inspect) if published
    end

    # @return [String]
    #
    def generate_publisher
      publisher = @metadata.at_css('publisher')
      add_setting_property(:publisher, publisher.text.strip.inspect) if publisher
    end

    # @return [String]
    #
    def generate_toc
      spine = @opf.at_css('spine')
      if spine.nil?
        UI.warning('No spine found in OPF file, skipping generating of table of contents')
        return
      end

      spine_items = spine.children
                         .select { |node| node.element? && node.name == 'itemref' }

      idrefs = spine_items.map { |itemref| itemref['idref'] }

      toc_id = spine['toc']
      return unless toc_id

      render_toc_item = lambda do |spine_item, toc_item|
        # ignore this item when it was already rendered
        next if spine_item && !idrefs.include?(spine_item['id'])

        spine_item ||= manifest_file_by_href(toc_item.href)

        href = toc_item&.href || spine_item['href']
        toc_item ||= @nav&.find { |n| n.href == href }

        href_output = href.sub(/\.x?html$/, '').sub(/\.x?html#/, '#')
        attribs = [href_output.inspect, toc_item&.title&.inspect].compact.join(', ')
        should_nest = toc_item && !toc_item.children.empty?

        if should_nest
          add_code(%(toc.file #{attribs} do), after: 'end') do
            toc_item.children.each do |child|
              render_toc_item.call(nil, child)
            end
          end
        else
          add_code(%(toc.file #{attribs}))
        end

        idrefs.delete(spine_item['id']) if spine_item
      end

      add_code('book.toc do |toc, target|', after: 'end') do
        spine_items.each do |itemref|
          next unless itemref.element?

          idref = itemref['idref']
          next unless idref

          item = manifest_file_by_id(idref)
          render_toc_item.call(item, nil)
        end
      end
    end

    private

    def add_code(code, commented: false, after: nil)
      indent_str = ' ' * @indent
      comment_prefix = commented ? '# ' : ''

      @bookspec << %(#{indent_str}#{comment_prefix}#{code})

      if block_given?
        increase_indent
        yield
        decrease_indent
      end

      add_code(after, commented: commented) if after
    end

    def add_setting_property(name, value, commented: false)
      if value.is_a?(Array)
        add_code(%(book.#{name} = [), commented: commented, after: ']') do
          value.each do |v|
            add_code(%(#{v},), commented: commented)
          end
        end
      else
        add_code(%(book.#{name} = #{value}), commented: commented)
      end
    end

    def add_comment(text)
      add_code(text, commented: true)
    end

    def add_empty_line
      @bookspec << ''
    end

    def increase_indent
      @indent += 2
    end

    def decrease_indent
      @indent -= 2
      @indent = 0 if @indent.negative?
    end

    def find_refines(id, property)
      @opf.at_css(%(meta[refines="##{id}"][property="#{property}"]))&.text
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

    # Compares two contributors by file_as, it will return true if file_as is same even when case is different
    #
    # @param [String] file_as_a
    # @param [String] file_as_b
    #
    # @return [Boolean]
    #
    def contributor_file_as_eq?(file_as_a, file_as_b)
      file_as_a == file_as_b || file_as_a.mb_chars.downcase == file_as_b.mb_chars.downcase
    end

    # @param [Nokogiri::XML::Element] li_node
    #
    # @return [NavItem]
    #
    def _parse_nav_xhtml_item(li_node)
      href = li_node.at_css('a')['href']
      title = li_node.at_css('a').text

      item = NavItem.new(href, title)
      item.children = li_node.css('ol > li').map { |p| _parse_nav_xhtml_item(p) }
      item
    end

    # @return [Array<NavItem>]
    #
    def _parse_nav_xhtml
      return nil if @nav_xhtml.nil?

      @nav_xhtml.css('nav[type="toc"] > ol > li')
                .map { |point| _parse_nav_xhtml_item(point) }
    end

    # @param [Nokogiri::XML::Element] point_node
    #
    # @return [NavItem]
    #
    def _parse_nav_ncx_item(point_node)
      href = point_node.at_css('content')['src']
      title = point_node.at_css('navLabel text')

      item = NavItem.new(href, title)
      item.children = point_node.css('> navPoint').map { |p| _parse_nav_ncx_item(p) }
      item
    end

    # @return [Array<NavItem>]
    #
    def _parse_nav_ncx
      @ncx.css('navMap > navPoint')
          .map { |point| _parse_nav_ncx_item(point) }
    end

    # @return [Array<NavItem>]
    #
    def _parse_nav
      if @nav_xhtml
        _parse_nav_xhtml
      elsif @ncx
        _parse_nav_ncx(@ncx)
      end
    end
  end
end
