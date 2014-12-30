require 'bundler/setup'
Bundler.setup

require 'pathname'
require 'fileutils'

require 'stylus'
require 'bade'

require_relative 'compiler/opf_generator'
require_relative 'compiler/nav_generator'
require_relative 'compiler/meta_inf_generator'

require_relative 'book'


module Epuber
  class Compiler

    EPUB_CONTENT_FOLDER = 'OEBPS'

    GROUP_EXTENSIONS = {
      text:  %w(.xhtml .html .md .bade),
      image: %w(.png .jpg .jpeg),
      font:  %w(.otf .ttf),
      style: %w(.css .styl),
    }.freeze

    STATIC_EXTENSIONS = %w(.xhtml .html .png .jpg .jpeg .otf .ttf .css).freeze

    EXTENSIONS_RENAME = {
      '.styl' => '.css',
      '.bade' => '.xhtml',
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
    def compile(build_folder)
      @all_files = []

      FileUtils.mkdir_p(build_folder)

      @output_dir = File.expand_path(build_folder)

      puts "  handling target #{@target.name.inspect} in build dir `#{build_folder}`"

      process_toc_item(@book.root_toc)
      process_target_files
      generate_other_files

      # build folder cleanup
      remove_unnecessary_files
      remove_empty_folders
    end

    # Archives current target files to epub
    #
    # @return [void]
    #
    def archive(path = epub_name)
      epub_path = File.expand_path(path)

      Dir.chdir(@output_dir) {
        all_files = Dir.glob('**/*')

        run_command(%{zip -q0X "#{epub_path}" mimetype})
        run_command(%{zip -qXr9D "#{epub_path}" "#{all_files.join('" "')}" --exclude \\*.DS_Store})
      }
    end

    # Creates name of epub file for current book and current target
    #
    # @return [String] name of result epub file
    #
    def epub_name
      epub_name = if !@book.output_base_name.nil?
                    @book.output_base_name
                  elsif @book.from_file?
                    File.basename(@book.file_path, File.extname(@book.file_path))
                  else
                    @book.title
                  end

      epub_name += @book.build_version.to_s unless @book.build_version.nil?
      epub_name += "-#{@target.name.to_s}" if @target != @book.default_target
      epub_name + '.epub'
    end


    private

    def remove_empty_folders
      Dir.chdir(@output_dir) {
        Dir.glob('**/*')
          .select { |d| File.directory?(d) }
          .select { |d| (Dir.entries(d) - %w[ . .. ]).empty? }
          .each { |d|
          puts "removing empty folder `#{d}`"
          Dir.rmdir(d)
        }
      }
    end

    def remove_unnecessary_files
      requested_paths = @all_files.map { |file|
        file.destination_path
      }.map { |path|
        # files have paths from EPUB_CONTENT_FOLDER
        pathname = Pathname.new(File.join(@output_dir, EPUB_CONTENT_FOLDER, path))
        pathname.relative_path_from(Pathname.new(@output_dir)).to_s
      }

      existing_paths = nil

      Dir.chdir(@output_dir) {
        existing_paths = Dir.glob('**/*')
      }

      unnecessary_paths = existing_paths - requested_paths

      # absolute path
      unnecessary_paths.map! { |path|
        File.join(@output_dir, path)
      }

      # remove directories
      unnecessary_paths.select! { |path|
        !File.directory?(path)
      }

      unnecessary_paths.each { |path|
        puts "removing unnecessary file: `#{path}`"
        File.delete(path)
      }
    end

    def generate_other_files
      # generate nav file (nav.xhtml or nav.ncx)
      nav_file = NavGenerator.new(@book, @target).generate_nav_file
      @target.add_to_all_files(nav_file)
      process_file(nav_file)

      # generate .opf file
      opf_file = OPFGenerator.new(@book, @target).generate_opf_file
      process_file(opf_file)

      # generate mimetype file
      mimetype_file                  = Epuber::Book::File.new(nil)
      mimetype_file.destination_path = '../mimetype'
      mimetype_file.content          = 'application/epub+zip'
      process_file(mimetype_file)

      # generate META-INF files
      meta_inf_files = MetaInfGenerator.new(@book, @target, File.join(EPUB_CONTENT_FOLDER, opf_file.destination_path)).generate_all_files
      meta_inf_files.each { |meta_file|
        process_file(meta_file)
      }
    end

    def process_target_files
      @target.files.select { |file|
        !file.only_one
      }.each { |file|
        files = find_files(file).map { |path| Epuber::Book::File.new(path) }
        @target.replace_file_with_files(file, files)
      }

      @target.files.each { |file|
        process_file(file)
      }

      cover_image = @target.cover_image
      unless cover_image.nil?
        destination_path_of_file(cover_image) # resolve destination path

        index = @target.all_files.index(cover_image)
        if index.nil?
          @target.add_to_all_files(cover_image)
        else
          file = @target.all_files[index]
          file.merge_with(cover_image)
        end
      end
    end

    # @param toc_item [Epuber::Book::TocItem]
    #
    def process_toc_item(toc_item)
      unless toc_item.file_obj.nil?
        file = toc_item.file_obj

        puts "    processing toc item #{file.source_path_pattern}"

        @target.add_to_all_files(file)
        process_file(file)
      end

      # process recursively other files
      toc_item.child_items.each { |child|
        process_toc_item(child)
      }
    end

    # @param file [Epuber::Book::File]
    #
    def process_file(file)
      dest_path = Pathname.new(destination_path_of_file(file))
      FileUtils.mkdir_p(dest_path.dirname)

      if !file.content.nil?
        # write file
        File.open(dest_path.to_s, 'w') { |file_handle|
          file_handle.write(file.content)
        }
      elsif !file.real_source_path.nil?
        file_pathname = Pathname.new(file.real_source_path)

        case file_pathname.extname
        when *STATIC_EXTENSIONS
          FileUtils.cp(file_pathname.to_s, dest_path.to_s)
        when '.styl'
          file.content = Stylus.compile(::File.new(file_pathname))
          return process_file(file)
        when '.bade'
          parsed = Bade::Parser.new(file: file_pathname.to_s).parse(::File.read(file_pathname.to_s))
          lam = Bade::RubyGenerator.node_to_lambda(parsed, new_line: '\n', indent: '  ')
          file.content = lam.call
          return process_file(file)
        else
          raise "unknown file extension #{file_pathname.extname} for file #{file.inspect}"
        end
      end

      @all_files << file
    end

    # @param file [Epuber::Book::File]
    # @return [String]
    #
    def destination_path_of_file(file)
      if file.destination_path.nil?
        real_source_path = find_file(file)

        extname = Pathname.new(real_source_path).extname
        new_extname = EXTENSIONS_RENAME[extname]

        dest_path = if new_extname.nil?
                      real_source_path
                    else
                      real_source_path.sub(/#{extname}$/, new_extname)
                    end

        file.destination_path = dest_path
        file.real_source_path = real_source_path

        File.join(@output_dir, EPUB_CONTENT_FOLDER, dest_path)
      else
        File.join(@output_dir, EPUB_CONTENT_FOLDER, file.destination_path)
      end
    end

    # @param pattern [String]
    # @param group [Symbol]
    # @return [Array<String>]
    #
    def file_paths_with_pattern(pattern, group = nil)
      file_paths = Dir.glob(pattern)

      file_paths.select! { |file_path|
        !file_path.include?(Command::BASE_PATH)
      }

      # filter depend on group
      unless group.nil?
        file_paths.select! { |file_path|
          extname = Pathname.new(file_path).extname
          group_array = GROUP_EXTENSIONS[group]

          raise "Uknown file group #{group.inspect}" if group_array.nil?

          group_array.include?(extname)
        }
      end

      file_paths
    end

    # @param file_or_pattern [String, Epuber::Book::File]
    # @return [String] only pattern
    #
    def pattern_from(file_or_pattern)
      if file_or_pattern.is_a?(Epuber::Book::File)
        file_or_pattern.source_path_pattern
      else
        file_or_pattern
      end
    end

    # @param file_or_pattern [String, Epuber::Book::File]
    # @param group [Symbol]
    # @return [Array<String>]
    #
    def find_files(file_or_pattern, group = nil)
      pattern = pattern_from(file_or_pattern)

      group = file_or_pattern.group if group.nil? && file_or_pattern.is_a?(Epuber::Book::File)

      file_paths = file_paths_with_pattern("**/#{pattern}", group)

      if file_paths.empty?
        file_paths = file_paths_with_pattern("**/#{pattern}.*", group)
      end

      file_paths
    end

    # @param file_or_pattern [String, Epuber::Book::File]
    # @param group [Symbol]
    # @return [String]
    #
    def find_file(file_or_pattern, group = nil)
      pattern = pattern_from(file_or_pattern)
      file_paths = find_files(file_or_pattern, group)

      raise "not found file matching pattern `#{pattern}`" if file_paths.empty?
      raise "found too many files for pattern `#{pattern}`" if file_paths.count >= 2

      file_paths.first
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

      code = $?
      raise 'wrong return value' if code != 0
    end
  end
end
