# encoding: utf-8

require 'fileutils'
require 'os'

require_relative '../command'


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
          ['--check',   'Performs additional validation on sources + checks result epub with epubcheck.'],
          ['--write',   'Performs additional transformations which writes to source files.'],
          ['--release', 'Create release version of the book, no caching, everything creates from scratch.'],
        ].concat(super)
      end

      # @param argv [CLAide::ARGV]
      #
      def initialize(argv)
        @targets_names = argv.arguments!
        @should_check = argv.flag?('check', false)
        @should_write = argv.flag?('write', false)
        @release_version = argv.flag?('release', false)

        super(argv)
      end

      def validate!
        super
        verify_one_bookspec_exists!
        verify_all_targets_exists!
      end

      def run
        super

        puts "compiling book `#{Config.instance.pretty_path_from_project(book.file_path)}`"

        if @release_version
          # Remove all previous versions of compiled files
          targets.each do |target|
            build_path = Epuber::Config.instance.release_build_path(target)

            if ::File.directory?(build_path)
              FileUtils.remove_dir(build_path, true)
            end
          end

          # Build all targets to always clean directory
          targets.each do |target|
            compiler = Epuber::Compiler.new(book, target)
            compiler.compile(Epuber::Config.instance.release_build_path(target), check: true, write: @should_write, release: true, verbose: verbose?)

            archive_name = compiler.epub_name

            if ::File.exists?(archive_name)
              FileUtils.remove_file(archive_name)
            end

            archive_path = compiler.archive(archive_name)

            system(%(epubcheck "#{archive_path}"))

            convert_epub_to_mobi(archive_path, ::File.basename(archive_path, '.epub') + '.mobi') if target.create_mobi
          end
        else
          targets.each do |target|
            compiler = Epuber::Compiler.new(book, target)
            compiler.compile(Epuber::Config.instance.build_path(target), check: @should_check, write: @should_write, verbose: verbose?)
            archive_path = compiler.archive(configuration_suffix: 'debug')

            system(%(epubcheck "#{archive_path}")) if @should_check

            convert_epub_to_mobi(archive_path, ::File.basename(archive_path, '.epub') + '.mobi') if target.create_mobi
          end
        end

        write_lockfile
      end

      private

      # @return [Array<Epuber::Book::Target>]
      #
      def targets
        @targets ||= (
          targets = @targets_names

          # when the list of targets is nil pick all available targets
          if targets.empty?
            book.targets
          else
            targets.map { |target_name| book.target_named(target_name) }
          end
        )
      end

      def verify_all_targets_exists!
        index = targets.index(&:nil?)
        help! "Not found target `#{@targets_names[index]}' in bookspec `#{book.file_path}'" unless index.nil?
      end

      def validate_dir(path)
        if ::File.directory?(path)
          path
        end
      end

      def find_calibre_app
        locations = `mdfind "kMDItemCFBundleIdentifier == net.kovidgoyal.calibre"`.split("\n")
        UI.error!("Can't find location of calibre.app to convert EPUB to MOBI.") if locations.empty?

        selected = locations.first
        UI.warn("Using calibre.app at location #{selected}") if locations.count > 1

        selected
      end

      def find_calibre_convert_file
        if OS.osx?
          ::File.join(find_calibre_app, 'Contents/MacOS/ebook-convert')
        elsif OS.linux?
          script_path = '/usr/bin/ebook-convert'
          UI.error!("Can't find ebook-convert in folder /usr/bin to convert EPUB to MOBI.") unless ::File.executable?(script_path)
          script_path
        else
          UI.error!('Unsupported OS to convert EPUB to MOBI.')
        end
      end

      def convert_epub_to_mobi(epub_path, mobi_path)
        system(find_calibre_convert_file, epub_path, mobi_path)
      end
    end
  end
end
