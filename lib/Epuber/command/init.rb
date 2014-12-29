require 'fileutils'
require 'colorize'

require_relative '../command'


module Epuber
  class Command
    class Init < Command
      self.summary = 'Init'

      def validate!
        existing = Dir.glob('*.bookspec')
        raise "Can't reinit this folder, #{existing.first} already exists." unless existing.empty?
      end

      def run
        print_welcome

        book_title = ask('Book title: ')
        book_id = ask('Book ID (basically simplified book title): ')

        write_gitignore
        write_bookspec(book_title, book_id)

        FileUtils.mkdir_p('images')
        FileUtils.mkdir_p('fonts')
        FileUtils.mkdir_p('styles')
        write_default_style(book_id)

        FileUtils.mkdir_p('text')

        print_good_bye(book_id)
      end


      private

      def print_welcome
        puts <<-END.yellow
Welcome to epuber init script. It will create basic structure for this project.
There will be some questions about basic information, please fill them.
END
      end

      def print_good_bye(book_id)
        puts <<-END.green
Success.
Epuber now ends.

Please review #{book_id}.bookspec file, remove comments, etc.

Bye :)
END
      end

      # Creates .bookspec file from template
      #
      # @param book_title [String]
      # @param book_id [String]
      #
      # @return [void]
      #
      def write_bookspec(book_title, book_id)
        template_path = File.expand_path(File.join('..', 'init_structure', 'template.bookspec'), File.dirname(__FILE__))
        rendered = render_file_template(template_path, book_title: book_title, book_id: book_id)
        write("#{book_id}.bookspec", rendered)
      end

      # Creates .gitignore file
      #
      # @return [void]
      #
      def write_gitignore
        write('.gitignore', <<-END
# This is generated with `epuber init`
*.epub
.epuber/
        END
        )
      end

      def write_default_style(book_id)
        write("styles/#{book_id}.styl", <<-END
// This is generated with `epuber init` script.
        END
        )
      end

      # @param file_path [String] path to template file
      #
      # @return [String] rendered template
      #
      def render_file_template(file_path, vars = {})
        require_relative '../vendor/hash_binding'
        hash_binding = Epuber::HashBinding.new(vars)
        b = hash_binding.get_binding
        string = ::File.read(file_path)
        eval_string = %Q{%Q{#{string}}}
        eval(eval_string, b, file_path)
      end

      # @param string [String] text to file
      # @param file_path [String] path to file
      #
      # @return [void]
      #
      def write(file_path, string)
        File.write(file_path, string)
      end

      # @param text [String]
      #
      # @return [String] returned text without new line
      #
      def ask(text)
        puts Dir.pwd

        print text
        result = $stdin.gets.chomp

        while result.empty?
          puts 'Value cannot be empty, please fill it!'.red
          print text
          result = $stdin.gets.chomp
        end

        result
      end
    end
  end
end