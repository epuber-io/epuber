# encoding: utf-8

require 'fileutils'

require_relative '../command'
require_relative '../vendor/ruby_templater'


module Epuber
  class Command
    class Init < Command
      self.summary = 'Initialize current folder to use it as Epuber project'
      self.arguments = [
        CLAide::Argument.new('PROJECT_NAME', false, true),
      ]

      # @param argv [CLAide::ARGV]
      #
      def initialize(argv)
        @book_name = argv.arguments!.first

        super(argv)
      end

      def validate!
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
        puts <<-END.ansi.green
Project initialized, please review #{book_id}.bookspec file, remove comments and fill some attributes like book title.
END
      end

      # Creates <book-id>.bookspec file from template
      #
      # @param book_id [String]
      #
      # @return [void]
      #
      def write_bookspec(book_id)
        template_path = File.expand_path(File.join('..', 'templates', 'template.bookspec'), File.dirname(__FILE__))
        rendered = Epuber::RubyTemplater.from_file(template_path)
                                        .with_locals(book_id: book_id)
                                        .render

        write("#{book_id}.bookspec", rendered)
      end

      # Creates <book-id>.sublime-project
      #
      # @param book_id [String]
      #
      # @return [void]
      #
      def write_sublime_project(book_id)
        text = '{
  "folders": [
    {
      "follow_symlinks": true,
      "path": ".",
      "folder_exclude_patterns": [".epuber"],
      "file_exclude_patterns": ["*.epub"]
    }
  ]
}'

        write("#{book_id}.sublime-project", text)
      end

      # Creates .gitignore file
      #
      # @return [void]
      #
      def write_gitignore
        write('.gitignore', <<-END
# This is generated with `epuber init`
*.epub
*.mobi
!.epuber/
.epuber/build/
.epuber/release_build/
.epuber/build_cache/
.epuber/metadata/

        END
        )
      end

      def write_default_style(book_id)
        write("styles/#{book_id}.styl", <<-END
// This is generated with `epuber init` script.
        END
        )
      end

      # @param string [String] text to file
      # @param file_path [String] path to file
      #
      # @return [void]
      #
      def write(file_path, string)
        File.write(file_path, string)
        puts "   #{'create'.ansi.green}  #{file_path}"
      end

      # @param [String] dir_path path to dir
      #
      # @return [nil]
      #
      def create_folder(dir_path)
        FileUtils.mkdir_p(dir_path)
        puts "   #{'create'.ansi.green}  #{dir_path}/"
      end

      # @param text [String]
      #
      # @return [String] returned text without new line
      #
      def ask(text)
        print text
        result = $stdin.gets.chomp

        while result.empty?
          puts 'Value cannot be empty, please fill it!'.ansi.red
          print text
          result = $stdin.gets.chomp
        end

        result
      end
    end
  end
end
