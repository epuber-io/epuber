
require_relative 'main_controller/opf'

require_relative 'book'


module Epuber
  class MainController
    include OPF

    # @param targets [Array<String>] targets names
    #
    def compile_targets(targets)

      Dir.glob('*.bookspec').each do |bookspec_file_path|
        # @type book [Book::Book]
        book = Book::Book.from_file(bookspec_file_path)

        book.validate

        targets.each do |target_name|
          target = self.target_named(book, target_name)

          raise "Not found target with name #{target_name}" if target.nil?

          # compile files

          # pack to epub file
        end
      end
    end

    # @param book [Epuber::Book::Book]
    # @param target_name [String]
    #
    # @return [Epuber::Book::Target]
    #
    def target_named(book, target_name)
      book.targets.find { |target|
        target.name == target_name
      }
    end
  end
end
