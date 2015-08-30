# encoding: utf-8

require 'English'

require 'pathname'
require 'fileutils'

require 'stylus'
require 'bade'
require 'zip'

require 'RMagick'

require_relative 'vendor/nokogiri_extensions'

require_relative 'plugin'


module Epuber
  class Compiler
    require_relative 'compiler/opf_generator'
    require_relative 'compiler/nav_generator'
    require_relative 'compiler/meta_inf_generator'

    require_relative 'compiler/file'
    require_relative 'compiler/file_resolver'

    require_relative 'compiler/file_processing'
    include FileProcessing


    EPUB_CONTENT_FOLDER = 'OEBPS'

    # @return [Epuber::GlobalsContext]
    #
    def self.globals_catcher
      @globals_catcher ||= GlobalsContext.new
    end

    # @return [Epuber::Compiler::FileResolver]
    #
    attr_reader :file_resolver

    # @return [Array<Epuber::Plugin>]
    #
    attr_reader :plugins

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
    # @param [Bool] check should run non-release checkers
    # @param [Bool] write should perform transformations of source files and write them back
    # @param [Bool] release this is release build
    #
    # @return [void]
    #
    def compile(build_folder, check: false, write: false, release: false)
      self.class.globals_catcher.catch do
        @file_resolver = FileResolver.new(Config.instance.project_path, build_folder)
        @should_check = check
        @should_write = write
        @release_build = release
        @plugins = []

        FileUtils.mkdir_p(build_folder)

        puts "  handling target #{@target.name.inspect} in build dir `#{build_folder}`"

        # parse plugins
        parse_plugins

        parse_toc_item(@target.root_toc)
        parse_target_file_requests

        process_all_target_files
        generate_other_files

        # build folder cleanup
        remove_unnecessary_files
        remove_empty_folders
      end
    ensure
      self.class.globals_catcher.clear_all
    end

    # Parse uses from current target
    #
    # @return nil
    #
    def parse_plugins
      @plugins += @target.plugins.map do |path|
        Plugin.new(::File.expand_path(path, Config.instance.project_path))
      end
    end

    # Archives current target files to epub
    #
    # @param path [String] path to created archive
    #
    # @return [String] path
    #
    def archive(path = nil, configuration_suffix: nil)
      path ||= epub_name(configuration_suffix)

      epub_path = ::File.expand_path(path)
      base_path = ::File.join(@file_resolver.destination_path, '')

      Dir.chdir(@file_resolver.destination_path) do
        new_paths = @file_resolver.files_of(:package).map(&:destination_path).map do |file_path|
          file_path.sub(base_path, '')
        end

        if ::File.exists?(epub_path)
          Zip::File.open(epub_path, true) do |zip_file|
            old_paths = zip_file.instance_eval { @entry_set.entries.map(&:name) }
            diff = old_paths - new_paths
            diff.each do |file_to_remove|
              puts "DEBUG: removing file from result EPUB: #{file_to_remove}"
              zip_file.remove(file_to_remove)
            end
          end
        end

        run_command(%(zip -q0X "#{epub_path}" mimetype))
        run_command(%(zip -qXr9D "#{epub_path}" "#{new_paths.join('" "')}" --exclude \\*.DS_Store))
      end

      path
    end

    # Creates name of epub file for current book and current target
    #
    # @return [String] name of result epub file
    #
    def epub_name(configuration_suffix = nil)
      epub_name = if !@book.output_base_name.nil?
                    @book.output_base_name
                  elsif @book.from_file?
                    ::File.basename(@book.file_path, ::File.extname(@book.file_path))
                  else
                    @book.title
                  end

      epub_name += @book.build_version.to_s unless @book.build_version.nil?
      epub_name += "-#{@target.name}" if @target != @book.default_target
      epub_name += "-#{configuration_suffix}" unless configuration_suffix.nil?
      epub_name + '.epub'
    end


    private

    # @return nil
    #
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

    # @return nil
    #
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
        puts "DEBUG: removing unnecessary file: `#{path}`"
        ::File.delete(path)
      end
    end

    # @return nil
    #
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
      mimetype_file = Epuber::Compiler::File.new(nil)
      mimetype_file.package_destination_path = 'mimetype'
      mimetype_file.content                  = 'application/epub+zip'
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

    # @return nil
    #
    def parse_target_file_requests
      @target.files.each do |file_request|
        if file_request.only_one
          @file_resolver.add_file(File.new(file_request))
        else
          @file_resolver.add_files(file_request)
        end
      end
    end

    # @return nil
    #
    def process_all_target_files
      @file_resolver.files_of(:manifest).each do |file|
        process_file(file)
      end
    end

    # @param toc_item [Epuber::Book::TocItem]
    #
    def parse_toc_item(toc_item)
      unless toc_item.file_request.nil?
        file_request = toc_item.file_request
        @file_resolver.add_file(File.new(file_request), type: :spine)
      end

      # process recursively other files
      toc_item.sub_items.each do |child|
        parse_toc_item(child)
      end
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
