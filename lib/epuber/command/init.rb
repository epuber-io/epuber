# frozen_string_literal: true

require 'fileutils'

require_relative '../templates'
require_relative '../command'
require_relative '../vendor/ruby_templater'

module Epuber
  class Command
    class Init < Command
      self.summary = 'Initialize current folder to use it as Epuber project'
      self.arguments = [
        CLAide::Argument.new('PROJECT_NAME', false),
      ]

      # @param [CLAide::ARGV] argv
      #
      def initialize(argv)
        @book_name = argv.arguments!.first

        super(argv)
      end

      def validate!
        super

        help! 'You must specify identifier-like name of the book as first argument' if @book_name.nil?

        existing = Dir.glob('*.bookspec')
        help! "Can't reinit this folder, #{existing.first} already exists." unless existing.empty?
      end

      def run
        super

        write_gitignore
        write_bookspec(@book_name)
        write_sublime_project(@book_name)

        create_folder('images')
        create_folder('fonts')
        create_folder('styles')
        write_default_style(@book_name)

        create_folder('text')

        print_good_bye(@book_name)
      end


      private

      def print_good_bye(book_id)
        UI.info <<~TEXT.ansi.green
          Project initialized, please review #{book_id}.bookspec file, remove comments and fill some attributes like book title.
        TEXT
      end

      # Creates <book-id>.bookspec file from template
      #
      # @param [String] book_id
      #
      # @return [void]
      #
      def write_bookspec(book_id)
        rendered = Epuber::RubyTemplater.from_file(Templates::TEMPLATE_BOOKSPEC)
                                        .with_locals(book_id: book_id)
                                        .render

        write("#{book_id}.bookspec", rendered)
      end

      # Creates <book-id>.sublime-project
      #
      # @param [String] book_id
      #
      # @return [void]
      #
      def write_sublime_project(book_id)
        text = <<~JSON
          {
            "folders": [
              {
                "follow_symlinks": true,
                "path": ".",
                "folder_exclude_patterns": [".epuber"],
                "file_exclude_patterns": ["*.epub"]
              }
            ]
          }
        JSON

        write("#{book_id}.sublime-project", text)
      end

      # Creates .gitignore file
      #
      # @return [void]
      #
      def write_gitignore
        append_new_lines('.gitignore', <<~TEXT)
          # This is generated with `epuber init`
          *.epub
          *.mobi
          !.epuber/
          .epuber/build/
          .epuber/release_build/
          .epuber/build_cache/
          .epuber/metadata/
        TEXT
      end

      def write_default_style(book_id)
        write("styles/#{book_id}.styl", <<~STYLUS)
          // This is generated with `epuber init` script.
        STYLUS
      end

      # @param [String] string text to file
      # @param [String] file_path path to file
      #
      # @return [void]
      #
      def write(file_path, string)
        File.write(file_path, string)
        UI.info "   #{'create'.ansi.green}  #{file_path}"
      end

      # @param [String] string text to file
      # @param [String] file_path path to file
      #
      # @return [void]
      #
      def append_new_lines(file_path, string)
        unless File.exist?(file_path)
          write(file_path, string)
          return
        end

        existing_content = File.read(file_path)
        string.split("\n").each do |line|
          next if existing_content.include?(line)

          existing_content << "\n#{line}"
        end

        existing_content << "\n"

        File.write(file_path, existing_content)
        UI.info "   #{'update'.ansi.green}  #{file_path}"
      end

      # @param [String] dir_path path to dir
      #
      # @return [nil]
      #
      def create_folder(dir_path)
        FileUtils.mkdir_p(dir_path)
        UI.info "   #{'create'.ansi.green}  #{dir_path}/"
      end

      # @param [String] text
      #
      # @return [String] returned text without new line
      #
      def ask(text)
        print text
        result = $stdin.gets.chomp

        while result.empty?
          UI.info 'Value cannot be empty, please fill it!'.ansi.red
          print text
          result = $stdin.gets.chomp
        end

        result
      end
    end
  end
end
