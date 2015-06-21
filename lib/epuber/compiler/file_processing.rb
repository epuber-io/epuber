# encoding: utf-8

require_relative 'file_resolver'
require_relative 'file'

require_relative '../book/file_request'
require_relative '../checker'
require_relative '../transformer'

module Epuber
  class Compiler
    module FileProcessing
      # @param file [Epuber::Compiler::File]
      #
      # @return nil
      #
      def process_file(file)
        dest_path = file.destination_path
        FileUtils.mkdir_p(::File.dirname(dest_path))

        if !file.content.nil?
          from_source_and_old = !file.source_path.nil? && !FileUtils.uptodate?(dest_path, [file.source_path])
          if from_source_and_old
            # invalidate old content
            file.content = nil

            return process_file(file)
          end

          file_write(file)
        elsif !file.source_path.nil?
          file_source_path = file.source_path
          file_extname = ::File.extname(file_source_path)

          case file_extname
          when *FileResolver::GROUP_EXTENSIONS[:text]
            process_text_file(file)
          when *FileResolver::GROUP_EXTENSIONS[:image]
            process_image_file(file)
          when *FileResolver::STATIC_EXTENSIONS
            file_copy(file)
          when '.styl'
            file.content = Stylus.compile(::File.new(file_source_path))
            file_write(file)
          else
            raise "unknown file extension #{file_extname} for file #{file.inspect}"
          end
        else
          raise "don't know what to do with file #{file.inspect} at path #{file.source_path}"
        end
      end

      # @param file [Epuber::Compiler::File]
      #
      # @return nil
      #
      def process_image_file(file)
        dest_path = file.destination_path
        source_path = file.source_path

        return if FileUtils.uptodate?(dest_path, [source_path])

        img = Magick::Image::read(source_path).first

        resolution = img.columns * img.rows
        max_resolution = 3_000_000

        if resolution > max_resolution
          img = img.change_geometry("#{max_resolution}@>") do |width, height, img|
            puts "DEBUG: downscaling image #{source_path} from resolution #{img.columns}x#{img.rows} to #{width}x#{height}"
            img.resize!(width, height)
          end

          img.write(dest_path)
        else
          file_copy(file)
        end
      end

      # @param file [Epuber::Compiler::File]
      #
      # @return nil
      #
      def process_text_file(file)
        source_path    = file.source_path
        source_extname = ::File.extname(source_path)

        variables = {
          __book: @book,
          __target: @target,
          __file_resolver: @file_resolver,
          __file: file,
          __const: Hash.new { |_hash, key| UI.warning("Undefined constant with key `#{key}`", location: caller_locations[0]) }.merge!(@target.constants),
        }

        file_content = ::File.read(source_path)

        if @should_write
          perform_plugin_things(Transformer, :source_text_file) do |transformer|
            file_content = transformer.call(file.destination_path, file_content)
          end

          _write(file_content, source_path)
        end

        xhtml_content   = case source_extname
                          when '.xhtml'
                            file_content
                          when '.rxhtml'
                            RubyTemplater.from_source(file_content, source_path).with_locals(variables)
                                         .render
                          when '.bade'
                            Bade::Renderer.from_source(file_content, source_path).with_locals(variables)
                                          .render(new_line: '', indent: '')
                          else
                            raise "Unknown text file extension #{source_extname}"
                          end

        xhtml_doc = xml_document_from_string(xhtml_content)
        xhtml_doc.file_path = source_path

        text_add_missing_root_elements(xhtml_doc)
        text_add_default_styles(file, xhtml_doc)
        text_add_default_viewport(file, xhtml_doc)
        text_detect_usage_of_javascript(file, xhtml_doc)
        text_resolve_links(file, xhtml_doc)
        text_parse_images(file, xhtml_doc)

        result_xhtml_s = xhtml_doc.to_xml(indent: 0, encoding: 'UTF-8', save_with: 0)

        # perform transformations
        perform_plugin_things(Transformer, :result_text_xhtml_string) do |transformer|
          result_xhtml_s = transformer.call(file.destination_path, result_xhtml_s)
        end

        # perform custom validation
        if @should_check
          perform_plugin_things(Checker, :result_text_xhtml_string) do |checker|
            checker.call(file.destination_path, result_xhtml_s)
          end
        end

        file.content = result_xhtml_s
        file_write(file)
      end

      # @param [String] text
      #
      # @return [Nokogiri::XML::Document]
      #
      def xml_document_from_string(text)
        doc = Nokogiri::XML.parse(text)
        doc.encoding = 'UTF-8'

        fragment = Nokogiri::XML.fragment(text)
        root_elements = fragment.children.select { |el| el.element? }

        if root_elements.count == 1
          doc.root = root_elements.first
        elsif fragment.at_css('body').nil?
          doc.root = doc.create_element('body')

          fragment.children.select do |child|
            child.element? || child.comment? || child.text?
          end.each do |child|
            doc.root.add_child(child)
          end
        end

        doc
      end

      # @param [Epuber::Compiler::File] file
      # @param [Nokogiri::XML::Document] xhtml_doc
      #
      # @return nil
      #
      def text_add_default_viewport(file, xhtml_doc)
        return if @target.default_viewport.nil?

        head = xhtml_doc.at_css('html > head')
        return unless head.at_css("meta[name='viewport']").nil?

        s = @target.default_viewport
        head << xhtml_doc.create_element('meta', name: 'viewport', content: "width=#{s.width},height=#{s.height}")
      end

      # @param [Epuber::Compiler::File] file
      # @param [Nokogiri::XML::Document] xhtml_doc
      #
      # @return nil
      #
      def text_resolve_links(file, xhtml_doc)
        _text_resolve_links_for(file, xhtml_doc, 'a', 'href')
        _text_resolve_links_for(file, xhtml_doc, 'map > area', 'href')
      end

      # @param [Epuber::Compiler::File] file
      # @param [Nokogiri::XML::Document] xhtml_doc
      # @param [String] tag_name CSS selector for tag
      # @param [String] attribute_name name of attribute
      #
      # @return nil
      #
      def _text_resolve_links_for(file, xhtml_doc, tag_name, attribute_name)
        img_nodes = xhtml_doc.css("#{tag_name}[#{attribute_name}]")
        img_nodes.each do |node|
          src = node[attribute_name]
          # @type [String] src
          next if src.nil?

          if src.empty?
            UI.warning("Empty attribute `#{attribute_name}` for tag `#{tag_name}`", location: node)
            next
          end

          begin
            uri = URI(src)
          rescue
            begin
              uri = URI(URI::encode(src))
            rescue
              # skip not valid uri
              UI.warning("Invalid link `#{src}` in tag `#{tag_name}`", location: node)
              next
            end
          end

          # skip uri with scheme (links to web pages)
          next unless uri.scheme.nil?

          # skip empty path
          next if uri.path.empty?

          target_file = _find_file_with_destination_pattern(uri.path, :text, ::File.dirname(file.destination_path), location: node)

          # skip not found files
          next if target_file.nil?

          uri.path = @file_resolver.relative_path(file, target_file)

          node[attribute_name] = uri.to_s
        end
      end

      # @param [FileResolver::FileNotFoundError, FileResolver::MultipleFilesFoundError] error
      #
      def _handle_file_resolver_error(error, location: nil)
        case error
        when FileResolver::FileNotFoundError
          UI.warning("Can't find file with name #{error.pattern}", location: location)

        when FileResolver::MultipleFilesFoundError
          UI.warning("Too many files found for name #{error.pattern} and there should be only one, files: #{error.files_paths}", location: location)
        end
      end

      # @param [String] pattern
      # @param [Symbol] group
      # @param [String] context_path
      #
      def _find_file_with_destination_pattern(pattern, group, context_path, location: nil)
        begin
          # try to find it in files folder
          @file_resolver.find_file_with_destination_pattern(pattern, context_path, group)
        rescue FileResolver::FileNotFoundError
          # try to find it in all files
          @file_resolver.find_file_with_destination_pattern(".*/#{pattern}", @file_resolver.destination_path, group)
        end
      rescue FileResolver::FileNotFoundError, FileResolver::MultipleFilesFoundError => e
        _handle_file_resolver_error(e, location: location)
      end

      # @param [Class] klass class of thing you want to perform (Checker or Transformer)
      # @param [Symbol] source_type source type of that thing (Checker or Transformer)
      #
      # @yield
      # @yieldparam [Epuber::CheckerTransformerBase] instance of checker or transformer
      #
      # @return nil
      #
      def perform_plugin_things(klass, source_type)
        plugins.each do |plugin|
          plugin.instances(klass).each do |instance|
            # @type checker [Epuber::CheckerTransformerBase]

            next if instance.source_type != source_type
            next if instance.options.include?(:run_only_before_release) && !@release_build

            yield instance
          end
        end
      end

      # @param file [Epuber::Compiler::File]
      # @param xhtml_doc [Nokogiri::XML::Document]
      #
      # @return nil
      #
      def text_parse_images(file, xhtml_doc)
        xhtml_doc.css('img').each do |img|
          path = img['src']
          next if path.nil?

          if path.empty?
            UI.warning('Empty attribute `href` for tag `img`', location: img)
            next
          end

          begin
            # try to find it in same folder
            package_path = @file_resolver.find_file(path, :image, context_path: ::File.dirname(file.source_path))
          rescue FileResolver::FileNotFoundError
            # try to find in project folder
            begin
              package_path = @file_resolver.find_file(path, :image)
            rescue FileResolver::FileNotFoundError, FileResolver::MultipleFilesFoundError => e
              _handle_file_resolver_error(e, location: img)
            end
          rescue FileResolver::MultipleFilesFoundError => e
            _handle_file_resolver_error(e, location: img)
          end

          # skip when no file was found (message was already show with #_handle_file_resolver_error method)
          next if package_path.nil?

          file_request = Epuber::Book::FileRequest.new(package_path, group: :image)
          image_file = File.new(file_request, group: :image)

          @file_resolver.add_file(image_file)

          relative_path = @file_resolver.relative_path(file, image_file)
          img['src'] = relative_path
        end
      end

      # @param file [Epuber::Compiler::File]
      # @param xhtml_doc [Nokogiri::XML::Document]
      #
      # @return nil
      #
      def text_detect_usage_of_javascript(file, xhtml_doc)
        unless xhtml_doc.at_css('script').nil?
          file.add_property(:scripted)
        end
      end

      # @param xhtml_doc [Nokogiri::XML::Document]
      #
      # @return nil
      #
      def text_add_missing_root_elements(xhtml_doc)
        # add missing body element
        if xhtml_doc.at_css('body').nil?
          xhtml_doc.root.surround_with_element('body')
        end

        # add missing root html element
        if xhtml_doc.at_css('html').nil?
          attrs               = {}
          attrs['xmlns']      = 'http://www.w3.org/1999/xhtml'
          attrs['xmlns:epub'] = 'http://www.idpf.org/2007/ops' if @target.epub_version >= 3
          xhtml_doc.root.surround_with_element('html', attrs)
        end

        # add missing head in html
        if xhtml_doc.at_css('html > head').nil?
          html = xhtml_doc.css('html').first
          head = xhtml_doc.create_element('head')
          head << xhtml_doc.create_element('title', @book.title)

          html.children.first.before(head)
        end
      end

      # @return [Array<Epuber::Compiler::File>]
      #
      def default_styles
        @default_styles ||= @target.default_styles.map do |default_style_request|
          @file_resolver.find_files_from_request(default_style_request) || []
        end.flatten
      end

      # @param file [Epuber::Compiler::File]
      # @param xhtml_doc [Nokogiri::XML::Document]
      #
      # @return nil
      #
      def text_add_default_styles(file, xhtml_doc)
        head         = xhtml_doc.at_css('html > head')
        styles_hrefs = head.css('link[rel="stylesheet"]').map { |element| element.attribute('href').value }

        paths_to_insert = default_styles.map do |style_file|
          @file_resolver.relative_path(file, style_file)
        end.reject do |path|
          styles_hrefs.include?(path)
        end

        paths_to_insert.each do |path_to_insert|
          head << xhtml_doc.create_element('link', rel: 'stylesheet', href: path_to_insert, type: 'text/css')
        end
      end

      # @param file [Epuber::Compiler::File]
      #
      # @return nil
      #
      def file_write(file)
        _write(file.content, file.destination_path)
      end

      # @param file [Epuber::Compiler::File]
      #
      # @return nil
      #
      def file_copy(file)
        dest_path = file.destination_path
        source_path = file.source_path

        return if FileUtils.uptodate?(dest_path, [source_path])
        return if ::File.exists?(dest_path) && FileUtils.compare_file(dest_path, source_path)

        puts "DEBUG: copying file from #{source_path} to #{dest_path}"
        FileUtils.cp(source_path, dest_path)
      end

      # @param [#to_s] content anything, that can be converted to string and should be written to file
      # @param [String] to_path destination path
      #
      # @return nil
      #
      def _write(content, to_path)
        original_content = if ::File.exists?(to_path)
                             ::File.read(to_path)
                           end

        should_write = if original_content.nil?
                         true
                       elsif content.is_a?(String)
                         original_content != content
                       else
                         original_content != content.to_s
                       end

        return unless should_write

        puts "DEBUG: writing to file #{to_path}"

        ::File.open(to_path, 'w') do |file_handle|
          file_handle.write(content)
        end
      end
    end
  end
end
