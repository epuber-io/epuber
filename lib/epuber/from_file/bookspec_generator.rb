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

    # @param opf [Epuber::OpfFile]
    # @param nav [Nokogiri::XML::Document, nil]
    # @param ncx [Nokogiri::XML::Document, nil]
    #
    def initialize(opf, nav: nil, ncx: nil)
      @opf = opf

      @nav_xhtml = nav
      @nav_xhtml&.remove_namespaces!
      @ncx = ncx
      @ncx&.remove_namespaces!
      @nav = _parse_nav
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
      titles = @opf.metadata.css('title')
      titles.each do |title|
        is_main = titles.count == 1

        id = title['id']
        is_main = @opf.find_refines(id, 'title-type') == 'main' if id && !is_main

        add_comment('alternate title found from original EPUB file (Epuber supports only one title)') unless is_main
        add_setting_property(:title, title.text.inspect, commented: !is_main)
      end
    end

    # @return [void]
    #
    def generate_authors
      authors = @opf.metadata.css('creator')
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
        role = @opf.find_refines(id, 'role')
        file_as = @opf.find_refines(id, 'file-as')
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
      nodes = @opf.metadata.css('identifier')

      nodes.each do |id_node|
        value = id_node.text

        is_main = @opf.package['unique-identifier'] == id_node['id']
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
      language = @opf.metadata.at_css('language')
      add_setting_property(:language, language.text.strip.inspect) if language
    end

    # @return [String]
    #
    def generate_published
      published = @opf.metadata.at_css('date')
      add_setting_property(:published, published.text.strip.inspect) if published
    end

    # @return [String]
    #
    def generate_publisher
      publisher = @opf.metadata.at_css('publisher')
      add_setting_property(:publisher, publisher.text.strip.inspect) if publisher
    end

    # @return [String]
    #
    def generate_toc
      spine_items = @opf.spine_items.dup
      idrefs = spine_items.map(&:idref)

      render_toc_item = lambda do |manifest_item, toc_item|
        # ignore this item when it was already rendered
        next if manifest_item && !idrefs.include?(manifest_item['id'])

        manifest_item ||= @opf.manifest_file_by_href(toc_item.href)

        href = toc_item&.href || manifest_item['href']
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

        idrefs.delete(manifest_item['id']) if manifest_item
      end

      add_code('book.toc do |toc, target|', after: 'end') do
        spine_items.each do |itemref|
          idref = itemref.idref
          next unless idref

          item = @opf.manifest_file_by_id(idref)
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
