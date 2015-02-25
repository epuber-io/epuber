# encoding: utf-8

require 'bundler/setup'
Bundler.setup

require 'English'

require 'pathname'
require 'fileutils'

require 'stylus'
require 'bade'

require 'RMagick'

require_relative 'book'

require_relative 'vendor/nokogiri_extensions'



module Epuber
  class Compiler
    require_relative 'compiler/opf_generator'
    require_relative 'compiler/nav_generator'
    require_relative 'compiler/meta_inf_generator'
    require_relative 'compiler/file'
    require_relative 'compiler/file_resolver'

    EPUB_CONTENT_FOLDER = 'OEBPS'

    GROUP_EXTENSIONS = {
      text:  %w(.xhtml .html .md .bade .rxhtml),
      image: %w(.png .jpg .jpeg),
      font:  %w(.otf .ttf),
      style: %w(.css .styl),
    }.freeze

    STATIC_EXTENSIONS = %w(.xhtml .html .png .jpg .jpeg .otf .ttf .css).freeze

    EXTENSIONS_RENAME = {
      '.styl'   => '.css',

      '.bade'   => '.xhtml',
      '.rxhtml' => '.xhtml',
      '.md'     => '.xhtml',
    }.freeze

    # @param book [Epuber::Book::Book]
    # @param target [Epuber::Book::Target]
    #
    def initialize(book, target)
      @book = book
      @target = target
    end

    # Compile target to build folder
    #
    # @param build_folder [String] path to folder, where will be stored all compiled files
    #
    # @return [void]
    #
    def compile(build_folder, check: false)
      @file_resolver = FileResolver.new(Config.instance.project_path, build_folder)
      @should_check = check

      FileUtils.mkdir_p(build_folder)

      puts "  handling target #{@target.name.inspect} in build dir `#{build_folder}`"

      process_toc_item(@target.root_toc)

      process_target_files
      generate_other_files

      # build folder cleanup
      remove_unnecessary_files
      remove_empty_folders
    end

    # Archives current target files to epub
    #
    # @param path [String] path to created archive
    #
    # @return [String] path
    #
    def archive(path = epub_name)
      epub_path = ::File.expand_path(path)

      Dir.chdir(@file_resolver.destination_path) do
        all_files = Dir.glob('**/*')

        run_command(%(zip -q0X "#{epub_path}" mimetype))
        run_command(%(zip -qXr9D "#{epub_path}" "#{all_files.join('" "')}" --exclude \\*.DS_Store))
      end

      path
    end

    # Creates name of epub file for current book and current target
    #
    # @return [String] name of result epub file
    #
    def epub_name
      epub_name = if !@book.output_base_name.nil?
                    @book.output_base_name
                  elsif @book.from_file?
                    ::File.basename(@book.file_path, ::File.extname(@book.file_path))
                  else
                    @book.title
                  end

      epub_name += @book.build_version.to_s unless @book.build_version.nil?
      epub_name += "-#{@target.name}" if @target != @book.default_target
      epub_name + '.epub'
    end


    private

    def remove_empty_folders
      Dir.chdir(@file_resolver.destination_path) do
        Dir.glob('**/*')
          .select { |d| ::File.directory?(d) }
          .select { |d| (Dir.entries(d) - %w(. ..)).empty? }
          .each do |d|
          puts "removing empty folder `#{d}`"
          Dir.rmdir(d)
        end
      end
    end

    def remove_unnecessary_files
      output_dir = @file_resolver.destination_path

      requested_paths = @file_resolver.files_of(:package).map do |file|
        # files have paths from EPUB_CONTENT_FOLDER
        abs_path = ::File.expand_path(file.destination_path, ::File.join(output_dir, EPUB_CONTENT_FOLDER))
        abs_path.sub(::File.join(output_dir, ''), '')
      end

      existing_paths = nil

      Dir.chdir(output_dir) do
        existing_paths = Dir.glob('**/*')
      end

      unnecessary_paths = existing_paths - requested_paths

      # absolute path
      unnecessary_paths.map! do |path|
        ::File.join(output_dir, path)
      end

      # remove directories
      unnecessary_paths.select! do |path|
        !::File.directory?(path)
      end

      unnecessary_paths.each do |path|
        puts "removing unnecessary file: `#{path}`"
        ::File.delete(path)
      end
    end

    def generate_other_files
      # generate nav file (nav.xhtml or nav.ncx)
      nav_file = NavGenerator.new(@book, @target, @file_resolver).generate_nav_file
      @file_resolver.add_file(nav_file, type: :manifest)
      process_file(nav_file)

      # generate .opf file
      opf_file = OPFGenerator.new(@book, @target, @file_resolver).generate_opf_file
      @file_resolver.add_file(opf_file, type: :package)
      process_file(opf_file)

      # generate mimetype file
      mimetype_file                  = Epuber::Compiler::File.new(nil)
      mimetype_file.package_destination_path = 'mimetype'
      mimetype_file.content          = 'application/epub+zip'
      @file_resolver.add_file(mimetype_file, type: :package)
      process_file(mimetype_file)

      # generate META-INF files
      opf_path = opf_file.package_destination_path
      meta_inf_files = MetaInfGenerator.new(@book, @target, opf_path).generate_all_files
      meta_inf_files.each do |meta_file|
        @file_resolver.add_file(meta_file, type: :package)
        process_file(meta_file)
      end
    end

    def process_target_files
      @target.files.each do |file_request|
        if file_request.only_one
          @file_resolver.add_file(File.new(file_request))
        else
          @file_resolver.add_files(file_request)
        end
      end

      @file_resolver.files_of(:manifest).each do |file|
        process_file(file)
      end
    end

    # @param toc_item [Epuber::Book::TocItem]
    #
    def process_toc_item(toc_item)
      unless toc_item.file_request.nil?
        file_request = toc_item.file_request

        puts "    processing toc item #{file_request.source_pattern}"

        @file_resolver.add_file(File.new(file_request), type: :spine)
      end

      # process recursively other files
      toc_item.sub_items.each do |child|
        process_toc_item(child)
      end
    end

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
        when *GROUP_EXTENSIONS[:text]
          process_text_file(file)
        when *GROUP_EXTENSIONS[:image]
          process_image_file(file)
        when *STATIC_EXTENSIONS
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
    def process_text_file(file)
      source_path = file.source_path
      source_extname = ::File.extname(source_path)

      xhtml_content   = case source_extname
                        when '.xhtml'
                          ::File.read(source_path)
                        when '.rxhtml'
                          RubyTemplater.render_file(source_path)
                        when '.bade'
                          parsed = Bade::Parser.new(file: source_path).parse(::File.read(source_path))
                          lam    = Bade::RubyGenerator.node_to_lambda(parsed, new_line: '\n', indent: '  ')
                          lam.call
                        else
                          raise "Unknown text file extension #{source_extname}"
                        end

      xhtml_doc = Nokogiri::XML.parse(xhtml_content, nil, 'UTF-8')
      # @type xhtml_doc [Nokogiri::XML::Document]

      # add missing body element
      if xhtml_doc.at_css('body').nil?
        xhtml_doc.root.surround_with_element('body')
      end

      # add missing root html element
      if xhtml_doc.at_css('html').nil?
        attrs = {}
        attrs['xmlns'] = 'http://www.w3.org/1999/xhtml'
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

      head = xhtml_doc.at_css('html > head')
      styles_hrefs = head.css('link[rel="stylesheet"]').map { |element| element.attribute('href').value }

      paths_to_insert = @target.default_styles.map do |default_style_request|
        @file_resolver.find_files_from_request(default_style_request) || []
      end.flatten.map do |style_file|
        @file_resolver.relative_path(file, style_file)
      end.reject do |path|
        styles_hrefs.include?(path)
      end

      paths_to_insert.each do |path_to_insert|
        head << xhtml_doc.create_element('link', rel: 'stylesheet', href: path_to_insert, type: 'text/css')
      end

      # TODO: perform text transform
      # TODO: perform analysis

      file.content = xhtml_doc
      file_write(file)
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

    # @param cmd [String]
    #
    # @return [void]
    #
    # @raise if the return value is not 0
    #
    def run_command(cmd)
      system(cmd)

      $stdout.flush
      $stderr.flush

      code = $CHILD_STATUS
      raise 'wrong return value' if code != 0
    end
  end
end
