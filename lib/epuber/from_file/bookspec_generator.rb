# frozen_string_literal: true

require 'set'

module Epuber
  class BookspecGenerator
    class TocItem
      # @return [String]
      #
      attr_accessor :href

      # @return [String, nil]
      #
      attr_accessor :title

      # @return [Array<TocItem>]
      #
      attr_accessor :children

      # @return [Array<Symbol>]
      #
      attr_accessor :landmarks

      def initialize(href, title = nil, landmarks = [], children = [])
        @href = href
        @title = title
        @landmarks = landmarks
        @children = children
      end

      def attribs
        [href.inspect, title&.inspect, *landmarks.map(&:inspect)].compact.join(', ')
      end

      def ==(other)
        other.is_a?(TocItem) &&
          href == other.href &&
          title == other.title &&
          landmarks == other.landmarks &&
          children == other.children
      end

      def to_s(level = 0)
        indent = ' ' * level
        children_str = children.map { |c| c.to_s(level + 2) }.join("\n")
        %(#{indent}#{href.inspect} #{title.inspect} #{landmarks.inspect}\n#{children_str})
      end

      def inspect
        %(#<#{self.class.name} #{self}>)
      end
    end

    # @param [Epuber::OpfFile] opf
    # @param [Epuber::NavFile, nil] nav
    #
    def initialize(opf, nav)
      @opf = opf
      @nav = nav
    end

    # @return [String]
    #
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
        generate_cover
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
      name = author_node.text.strip
      id = author_node['id']

      if id
        role = @opf.find_refines(id, 'role')
        file_as = @opf.find_refines(id, 'file-as')
      end

      role ||= author_node['opf:role']
      file_as ||= author_node['opf:file-as']

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
        value = id_node.text.strip

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

    # @return [void]
    #
    def generate_language
      language = @opf.metadata.at_css('language')
      add_setting_property(:language, language.text.strip.inspect) if language
    end

    # @return [void]
    #
    def generate_published
      published = @opf.metadata.at_css('date')
      add_setting_property(:published, published.text.strip.inspect) if published
    end

    # @return [void]
    #
    def generate_publisher
      publisher = @opf.metadata.at_css('publisher')
      add_setting_property(:publisher, publisher.text.strip.inspect) if publisher
    end

    # @return [void]
    #
    def generate_cover
      cover_property = Compiler::OPFGenerator::PROPERTIES_MAP[:cover_image]

      cover_id = @opf.manifest_items.find { |_, item| item.properties&.include?(cover_property) }&.last&.id
      cover_id ||= @opf.metadata.at_css('meta[name="cover"]')&.[]('content')
      cover = @opf.manifest_file_by_id(cover_id) if cover_id
      return unless cover

      href = cover.href.sub(/#{Regexp.escape(File.extname(cover.href))}$/, '')
      add_setting_property(:cover_image, href.inspect)
    end

    # @return [void]
    #
    def generate_toc
      items = calculate_toc_items

      render_toc_item = lambda do |item|
        if item.children.empty?
          add_code(%(toc.file #{item.attribs}))
        else
          add_code(%(toc.file #{item.attribs} do), after: 'end') do
            item.children.each do |child|
              render_toc_item.call(child)
            end
          end
        end
      end

      add_code('book.toc do |toc, target|', after: 'end') do
        items.each do |toc_item|
          render_toc_item.call(toc_item)
        end
      end
    end

    private

    # Add code to final file. When block is given, it will be indented.
    #
    # @param [String] code  code to print into final file
    # @param [Boolean] commented should be code commented?
    # @param [String, nil] after code to print after this code
    #
    # @return [void]
    #
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
      return if @bookspec.last == ''

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

    # @param [String] href
    #
    # @return [Array<Symbol>]
    #
    def landmark_for_href(href)
      landmarks = @nav&.landmarks
      landmark_map = NavFile::LANDMARKS_MAP unless landmarks.nil?

      if landmarks.nil?
        landmarks = @opf.guide_items
        landmark_map = OpfFile::LANDMARKS_MAP
      end

      found = landmarks.select { |l| l.href == href }
                       .map(&:type)
                       .compact
                       .map { |t| landmark_map[t] }
                       .compact

      return found unless found.empty?

      # try to find by href without fragment
      if href.include?('#')
        href = href.split('#').first
        return landmark_for_href(href)
      end

      []
    end

    # @return [Array<Epuber::BookspecGenerator::TocItem>]
    #
    def calculate_toc_items
      spine_items = @opf.spine_items
      idrefs = spine_items.map(&:idref)
      landmarks = Set.new

      # @param [ManifestItem, nil] manifest_item
      # @param [NavItem, nil] toc_item
      #
      # @return [Array<Epuber::BookspecGenerator::TocItem>]
      #
      render_toc_item = lambda do |manifest_item, toc_item|
        # ignore this item when it was already rendered
        next nil if manifest_item && !idrefs.include?(manifest_item.id)

        manifest_item ||= @opf.manifest_file_by_href(toc_item.href)

        href = toc_item&.href || manifest_item.href
        toc_item ||= @nav&.find_by_href(href) || @nav&.find_by_href(href, ignore_fragment: true)
        href = toc_item&.href || manifest_item.href

        href_output = href.sub(/\.x?html$/, '')
                          .sub(/\.x?html#/, '#')

        landmarks_for_this = landmark_for_href(href)
        unless landmarks_for_this.empty?
          diff = Set.new(landmarks_for_this) - landmarks
          landmarks += diff

          landmarks_for_this = diff.to_a
        end

        item = TocItem.new(href_output, toc_item&.title, landmarks_for_this)
        item.children = toc_item&.children&.map do |child|
          render_toc_item.call(nil, child)
        end || []

        idrefs.delete(manifest_item.id) if manifest_item

        item
      end

      spine_items.map do |itemref|
        idref = itemref.idref
        next unless idref

        render_toc_item.call(@opf.manifest_file_by_id(idref), nil)
      end.compact
    end
  end
end
