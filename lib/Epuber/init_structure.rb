
require 'fileutils'
require 'ostruct'
require 'colorize'

module Epuber
  class InitStructure
    # Creates init structure for book
    #
    # @return [void]
    #
    def self.create
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
    end

    private

    class HashBinding
      def initialize(vars = {})
        @vars = vars
      end
      def method_missing(name)
        raise "Not found value for key #{name}" unless @vars.has_key?(name)
        @vars[name]
      end
      def get_binding
        binding
      end
    end

    def self.print_welcome
      puts <<-END.yellow
Welcome to epuber init script. It will create basic structure for this project:
  .gitignore
  <book-id>.bookspec
  images/
  fonts/
  styles/
    <book-id>.styl
  text/

It will ask you about some basic information, please fill them.
END
    end

    def self.print_good_bye(book_id)
      puts <<-END.yellow
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
    def self.write_bookspec(book_title, book_id)
      template_path = File.expand_path(File.join('init_structure', 'template.bookspec'), File.dirname(__FILE__))
      rendered = render_file_template(template_path, book_title: book_title, book_id: book_id)
      write("#{book_id}.bookspec", rendered)
    end

    # Creates .gitignore file
    #
    # @return [void]
    #
    def self.write_gitignore
      write('.gitignore', <<-END
# This is generated with `epuber init`
*.epub
.epuber/
      END
      )
    end

    def self.write_default_style(book_id)
      write("styles/#{book_id}.styl", <<-END
// This is generated with `epuber init` script.
END
)
    end

    # @param file_path [String] path to template file
    #
    # @return [String] rendered template
    #
    def self.render_file_template(file_path, vars = {})
      hash_binding = HashBinding.new(vars)
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
    def self.write(file_path, string)
      File.write(file_path, string)
    end

    # @param text [String]
    #
    # @return [String] returned text without new line
    #
    def self.ask(text)
      print text
      result = gets.chomp

      while result.empty?
        puts 'Value cannot be empty, please fill it!'.red
        print text
        result = gets.chomp
      end

      result
    end
  end
end
