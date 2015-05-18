# encoding: utf-8

require 'fileutils'

require_relative '../command'


module Epuber
  class Command
    class Compile < Command
      self.summary = 'Compile targets into multiple EPUB files.'
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

        puts "compiling book `#{book.file_path}`"

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
            compiler.compile(Epuber::Config.instance.release_build_path(target), check: true, write: @should_write, release: true)

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
            compiler.compile(Epuber::Config.instance.build_path(target), check: @should_check, write: @should_write)
            archive_path = compiler.archive(configuration_suffix: 'debug')

            system(%(epubcheck "#{archive_path}")) if @should_check

            convert_epub_to_mobi(archive_path, ::File.basename(archive_path, '.epub') + '.mobi') if target.create_mobi
          end
        end
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

      def convert_epub_to_mobi(epub_path, mobi_path)
        calibre_path = validate_dir('/Applications/calibre.app')
        calibre_path = validate_dir(File.join(Dir.home, 'Applications/calibre.app')) if calibre_path.nil?
        UI.error!("Can't find location of calibre.app, tried application folder /Applications and ~/Applications with application name calibre.app, please install calibre to one of those folders") if calibre_path.nil?

        # convert
        system(::File.join(calibre_path, 'Contents/MacOS/ebook-convert'), epub_path, mobi_path)
      end
    end
  end
end
