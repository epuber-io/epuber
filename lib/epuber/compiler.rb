# encoding: utf-8

require 'English'

require 'pathname'
require 'fileutils'

require 'zip'

require_relative 'vendor/nokogiri_extensions'
require_relative 'vendor/globals_context'

require_relative 'plugin'


module Epuber
  class Compiler
    require_relative 'compiler/compilation_context'

    require_relative 'compiler/opf_generator'
    require_relative 'compiler/nav_generator'
    require_relative 'compiler/meta_inf_generator'

    require_relative 'compiler/file_resolver'
    require_relative 'compiler/file_finders/normal'

    require_relative 'compiler/file_database'


    EPUB_CONTENT_FOLDER = 'OEBPS'

    # @return [Epuber::GlobalsContext]
    #
    def self.globals_catcher
      @globals_catcher ||= Epuber::GlobalsContext.new
    end

    # @return [Epuber::Compiler::FileResolver]
    #
    attr_reader :file_resolver

    # @return [CompilationContext]
    #
    attr_reader :compilation_context

    # @param book [Epuber::Book::Book]
    # @param target [Epuber::Book::Target]
    #
    def initialize(book, target)
      @book = book
      @target = target
      @compilation_context = CompilationContext.new(book, target)
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
    def compile(build_folder, check: false, write: false, release: false, verbose: false, use_cache: true)
      @file_resolver = FileResolver.new(Config.instance.project_path, build_folder)
      compilation_context.file_resolver = @file_resolver
      compilation_context.should_check = check
      compilation_context.should_write = write
      compilation_context.release_build = release
      compilation_context.verbose = verbose
      compilation_context.use_cache = use_cache

      self.class.globals_catcher.catch do
        @build_folder = build_folder

        FileUtils.mkdir_p(build_folder)

        puts "  handling target #{@target.name.inspect} in build dir `#{Config.instance.pretty_path_from_project(build_folder)}`"

        file_resolver.add_file(FileTypes::SourceFile.new(Config.instance.pretty_path_from_project(@book.file_path).to_s))
        compilation_context.plugins

        parse_toc_item(@target.root_toc)
        parse_target_file_requests

        process_all_target_files
        generate_other_files

        # build folder cleanup
        remove_unnecessary_files
        remove_empty_folders

        source_paths = file_resolver.files.select { |a| a.is_a?(FileTypes::SourceFile) }.map { |a| a.source_path }
        compilation_context.source_file_database.cleanup(source_paths)
        compilation_context.target_file_database.cleanup(source_paths)
      end
    ensure
      self.class.globals_catcher.clear_all

      compilation_context.source_file_database.save_to_file
      compilation_context.target_file_database.save_to_file
    end

    # Archives current target files to epub
    #
    # @param path [String] path to created archive
    #
    # @return [String] path
    #
    def archive(path = nil, configuration_suffix: nil)
      path ||= epub_name(configuration_suffix)

      epub_path = File.expand_path(path)

      Dir.chdir(@file_resolver.destination_path) do
        new_paths = @file_resolver.package_files.map(&:pkg_destination_path)

        if ::File.exists?(epub_path)
          Zip::File.open(epub_path, true) do |zip_file|
            old_paths = zip_file.instance_eval { @entry_set.entries.map(&:name) }
            diff = old_paths - new_paths
            diff.each do |file_to_remove|
              puts "DEBUG: removing file from result EPUB: #{file_to_remove}" if compilation_context.verbose?
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
          .select { |d| File.directory?(d) }
          .select { |d| (Dir.entries(d) - %w(. ..)).empty? }
          .each do |d|
          puts "DEBUG: removing empty folder `#{d}`" if compilation_context.verbose?
          Dir.rmdir(d)
        end
      end
    end

    # @return nil
    #
    def remove_unnecessary_files
      unnecessary_paths = @file_resolver.unneeded_files_in_destination.map { |path| File.join(@file_resolver.destination_path, path) }
      unnecessary_paths.each do |path|
        puts "DEBUG: removing unnecessary file: `#{Config.instance.pretty_path_from_project(path)}`" if compilation_context.verbose?

        File.delete(path)
      end
    end

    # @return nil
    #
    def generate_other_files
      # generate nav file (nav.xhtml or nav.ncx)
      nav_file = FileTypes::NavFile.new(@target.epub_version)
      @file_resolver.add_file(nav_file)
      process_file(nav_file)

      # generate .opf file
      opf_file = FileTypes::OPFFile.new
      @file_resolver.add_file(opf_file)
      process_file(opf_file)

      # generate mimetype file
      mimetype_file = FileTypes::MimeTypeFile.new
      @file_resolver.add_file(mimetype_file)
      process_file(mimetype_file)

      # generate META-INF files
      container_xml = FileTypes::ContainerXMLFile.new
      @file_resolver.add_file(container_xml)
      process_file(container_xml)

      if @target.epub_version >= 2.0 && @target.epub_version < 3.0
        ibooks_options = FileTypes::IBooksDisplayOptionsFile.new
        @file_resolver.add_file(ibooks_options)
        process_file(ibooks_options)
      end
    end

    # @return nil
    #
    def parse_target_file_requests
      @target.files.each do |file_request|
        @file_resolver.add_file_from_request(file_request)
      end
    end

    # @param [Epuber::Compiler::FileTypes::AbstractFile] file
    #
    def process_file(file)
      file.compilation_context = compilation_context

      resolve_dependencies(file) if file.is_a?(FileTypes::SourceFile)
      file.process(compilation_context)

      file.compilation_context = nil
    end

    # @param [FileTypes::SourceFile] file
    #
    def resolve_dependencies(file)
      deps = file.find_dependencies

      # compute better paths for FileDatabase
      dirname = File.dirname(file.source_path)
      paths = deps.map { |relative| Config.instance.pretty_path_from_project(File.expand_path(relative, dirname)) }.uniq

      # add missing files to file_resolver
      paths.each do |path|
        next if file_resolver.file_with_source_path(path)
        file_resolver.add_file(FileTypes::SourceFile.new(path))
      end

      # add .bookspec file
      paths += [Config.instance.pretty_path_from_project(@book.file_path).to_s]

      # add all activated plugin files
      paths += compilation_context.plugins.map do |plugin|
        plugin.files.map { |p_file| Config.instance.pretty_path_from_project(p_file.source_path) }
      end.flatten

      # add dependencies to databases
      source_db = compilation_context.source_file_database
      source_db.update_metadata(file.source_path) unless source_db.file_stat_for(file.source_path)
      source_db.add_dependency(paths, to: file.source_path)

      # add dependencies to databases
      target_db = compilation_context.target_file_database
      target_db.update_metadata(file.source_path) unless target_db.file_stat_for(file.source_path)
      target_db.add_dependency(paths, to: file.source_path)
    end

    # @return nil
    #
    def process_all_target_files
      @file_resolver.manifest_files.each_with_index do |file, idx|
        UI.print_processing_file(file, idx, @file_resolver.manifest_files.count)
        process_file(file)
      end

      UI.processing_files_done
    end

    # @param toc_item [Epuber::Book::TocItem]
    #
    def parse_toc_item(toc_item)
      unless toc_item.file_request.nil?
        file = @file_resolver.add_file_from_request(toc_item.file_request, :spine)
        file.toc_item = toc_item if file.toc_item.nil?
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
