
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
      def process_image_file(file)
        dest_path = file.destination_path
        source_path = file.source_path

        return if FileUtils.uptodate?(dest_path, [source_path])

        img = Magick::Image::read(source_path).first

        resolution = img.columns * img.rows
        max_resolution = 2_000_000
        if resolution > max_resolution
          scale = max_resolution.to_f / resolution.to_f
          puts "DEBUG: downscaling image #{source_path} with scale #{scale}"
          img.scale!(scale)
          img.write(dest_path)
        else
          file_copy(file)
        end
      end

      # @param file [Epuber::Compiler::File]
      #
      def process_text_file(file)
        source_path    = file.source_path
        source_extname = ::File.extname(source_path)

        variables = {
          __book: @book,
          __target: @target,
          __file_resolver: @file_resolver,
          __file: file,
        }

        xhtml_content   = case source_extname
                          when '.xhtml'
                            ::File.read(source_path)
                          when '.rxhtml'
                            RubyTemplater.render_file(source_path, variables)
                          when '.bade'
                            Bade::Renderer.from_file(source_path)
                                          .with_locals(variables)
                                          .render(new_line: '\n', indent: '  ')
                          else
                            raise "Unknown text file extension #{source_extname}"
                          end

        xhtml_doc = Nokogiri::XML.parse(xhtml_content, nil, 'UTF-8')
        # @type xhtml_doc [Nokogiri::XML::Document]

        text_add_missing_root_elements(xhtml_doc)
        text_add_default_styles(file, xhtml_doc)
        text_detect_usage_of_javascript(file, xhtml_doc)
        text_resolve_links(file, xhtml_doc)
        text_parse_images(file, xhtml_doc)

        result_xhtml_s = xhtml_doc.to_s

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

      # @param [Epuber::Compiler::File] file
      # @param [Nokogiri::XML::Document] xhtml_doc
      #
      # @return [nil]
      #
      def text_resolve_links(file, xhtml_doc)
        tag_name = 'a'
        attribute_name = 'href'
        group = :text

        img_nodes = xhtml_doc.css("#{tag_name}[#{attribute_name}]")
        img_nodes.each do |node|
          src = node[attribute_name]
          # @type [String] src

          unless src.nil?
            begin
              uri = URI(src)
            rescue
              # skip not valid uri
              next
            end

            # skip uri with scheme (links to web pages)
            next unless uri.scheme.nil?

            pattern = uri.path

            begin
              # try to find it in files folder
              target_file = @file_resolver.find_file_with_destination_pattern(pattern, ::File.dirname(file.destination_path), group)
            rescue FileResolver::FileNotFoundError, FileResolver::MultipleFilesFoundError
              # try to find it in all files
              target_file = @file_resolver.find_file_with_destination_pattern(".*/#{pattern}", @file_resolver.destination_path, group)
            end


            uri.path = @file_resolver.relative_path(file, target_file)

            node[attribute_name] = uri.to_s
          end
        end
      end

      # @param [Class] klass class of thing you want to perform (Checker or Transformer)
      # @param [Symbol] source_type source type of that thing (Checker or Transformer)
      #
      # @yield
      # @yieldparam [Epuber::CheckerTransformerBase] instance of checker or transformer
      #
      def perform_plugin_things(klass, source_type)
        plugins.each do |plugin|
          plugin.instances(klass).each do |instance|
            # @type checker [Epuber::CheckerTransformerBase]

            next if instance.source_type != source_type
            next if instance.options.include?(:run_only_before_release)

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

          begin
            # try to find it in same folder
            package_path = @file_resolver.find_file(path, :image, context_path: ::File.dirname(file.source_path))
          rescue FileResolver::FileNotFoundError
            # try to find in project folder
            package_path = @file_resolver.find_file(path, :image)
          end

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
      def file_write(file)
        dest_path = file.destination_path

        original_content = if ::File.exists?(dest_path)
                             ::File.read(dest_path)
                           end

        return if original_content == file.content || original_content == file.content.to_s

        puts "DEBUG: writing to file #{dest_path}"

        ::File.open(dest_path, 'w') do |file_handle|
          file_handle.write(file.content)
        end
      end

      # @param file [Epuber::Compiler::File]
      #
      def file_copy(file)
        dest_path = file.destination_path
        source_path = file.source_path

        return if FileUtils.uptodate?(dest_path, [source_path])
        return if ::File.exists?(dest_path) && FileUtils.compare_file(dest_path, source_path)

        puts "DEBUG: copying file from #{source_path} to #{dest_path}"
        FileUtils.cp(source_path, dest_path)
      end

    end
  end
end
