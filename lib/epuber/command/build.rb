# frozen_string_literal: true

require 'fileutils'
require 'os'

require_relative '../command'
require_relative '../epubcheck'

module Epuber
  class Command
    class Build < Command
      require_relative 'compile'

      self.summary = 'Build targets and produces output files.'
      self.arguments = [
        CLAide::Argument.new('TARGETS', false, true),
      ]

      def self.options
        [
          ['--check',    'Performs additional validation on sources + checks result epub with epubcheck.'],
          ['--write',    'Performs additional transformations which writes to source files.'],
          ['--release',  'Create release version of the book, no caching, everything creates from scratch.'],
          ['--no-cache', 'Turns off incremental build, can resolve some bugs but build takes much longer.'],
          ['--debug-steps-times', 'Shows times of each step'],
        ].concat(super)
      end

      # To resolve problem with `compile` treating as subcommand
      def self.subcommands
        []
      end

      # @param [CLAide::ARGV] argv
      #
      def initialize(argv)
        @targets_names = argv.arguments!
        @should_check = argv.flag?('check', false)
        @should_write = argv.flag?('write', false)
        @release_version = argv.flag?('release', false)
        @use_cache = argv.flag?('cache', true)

        UI.logger.debug_steps_times = argv.flag?('debug-steps-times', false)

        super
      end

      def validate!
        super
        verify_one_bookspec_exists!
        verify_all_targets_exists!

        pre_build_checks
      end

      def run
        super

        UI.info "building book `#{Config.instance.pretty_path_from_project(book.file_path)}`"

        if @release_version
          # Remove all previous versions of compiled files
          cleanup_build_folders

          # Build all targets to always clean directory
          targets.each do |target|
            Epuber::Config.instance.release_build = true

            compiler = Epuber::Compiler.new(book, target)
            build_path = Epuber::Config.instance.release_build_path(target)
            compiler.compile(build_path, check: true, write: @should_write,
                                         release: true, verbose: verbose?,
                                         use_cache: false)

            archive_name = compiler.epub_name

            FileUtils.rm_f(archive_name)

            archive_path = compiler.archive(archive_name)
            run_epubcheck(archive_path, build_path)
            convert_epub_to_mobi(archive_path, "#{::File.basename(archive_path, '.epub')}.mobi") if target.create_mobi

            Epuber::Config.instance.release_build = false
          end

          # Build all targets to always clean directory
        else
          targets.each do |target|
            compiler = Epuber::Compiler.new(book, target)
            build_path = Epuber::Config.instance.build_path(target)
            compiler.compile(build_path, check: @should_check, write: @should_write, verbose: verbose?,
                                         use_cache: @use_cache)
            archive_path = compiler.archive(configuration_suffix: 'debug')

            run_epubcheck(archive_path, build_path) if @should_check

            convert_epub_to_mobi(archive_path, "#{::File.basename(archive_path, '.epub')}.mobi") if target.create_mobi
          end
        end

        # Exit with error if there are any errors
        if (@release_version || @should_check) && Epuber::UI.logger.error?
          exit(1)
        else
          UI.info('🎉 Build finished successfully.'.ansi.green)
          write_lockfile
        end
      end

      private

      # @return [Array<Epuber::Book::Target>]
      #
      def targets
        @targets ||= begin
          targets = @targets_names

          # when the list of targets is nil pick all available targets
          if targets.empty?
            book.buildable_targets
          else
            targets.map { |target_name| book.target_named(target_name) }
          end
        end
      end

      def verify_all_targets_exists!
        index = targets.index(&:nil?)
        help! "Not found target `#{@targets_names[index]}' in bookspec `#{book.file_path}'" unless index.nil?
      end

      def validate_dir(path)
        return unless ::File.directory?(path)

        path
      end

      def run_epubcheck(archive_path, build_dir)
        UI.info("Running Epubcheck for #{archive_path}")

        report = Epubcheck.check(archive_path)
        report.problems.each do |problem|
          relative_path = problem.location.path.sub("#{archive_path}/", '')
          file_path = ::File.join(build_dir, relative_path)

          nice_path = Config.instance.pretty_path_from_project(file_path)
          content = ::File.read(file_path)

          log_level = case problem.level
                      when :fatal, :error then :error
                      when :warning then :warning
                      else :info
                      end
          message = "#{problem.level}(#{problem.code}): #{problem.message}"

          p = Compiler::Problem.new(problem.level, message, content, line: problem.location.lineno,
                                                                     column: problem.location.column,
                                                                     length: 1,
                                                                     file_path: nice_path)
          UI.send(log_level, p, backtrace: nil)
        end

        if report.error?
          UI.error('Epubcheck found some errors in epub file.')
        else
          UI.info('Epubcheck finished successfully.')
        end
      end

      def find_calibre_app
        locations = `mdfind "kMDItemCFBundleIdentifier == net.kovidgoyal.calibre"`.split("\n")
        UI.error!("Can't find location of calibre.app to convert EPUB to MOBI.") if locations.empty?

        selected = locations.first
        UI.warning("Found multiple calibre.app, using at location #{selected}") if locations.count > 1

        selected
      end

      def find_calibre_convert_file
        if OS.osx?
          ::File.join(find_calibre_app, 'Contents/MacOS/ebook-convert')
        elsif OS.linux?
          script_path = '/usr/bin/ebook-convert'
          unless ::File.executable?(script_path)
            UI.error!("Can't find ebook-convert in folder /usr/bin to convert EPUB to MOBI.")
          end
          script_path
        else
          UI.error!('Unsupported OS to convert EPUB to MOBI.')
        end
      end

      def convert_epub_to_mobi(epub_path, mobi_path)
        system(find_calibre_convert_file, epub_path, mobi_path)
      end

      def cleanup_build_folders
        targets.each do |target|
          build_path = Epuber::Config.instance.release_build_path(target)

          FileUtils.remove_dir(build_path, true) if ::File.directory?(build_path)
        end
      end
    end
  end
end
