# frozen_string_literal: true

module Epuber
  describe 'plugin' do # rubocop:disable RSpec/DescribeClass
    describe 'after all text files' do
      include_context 'with temp dir'

      it 'called after all text files are written' do
        write_file('after_all_text_files.rb', <<~RUBY)
          transform :after_all_text_files do |transformer, book, compilation_context|
            # this does not trigger any error
            not_existing_file = transformer.find_file('texta')

            file = transformer.find_file('text')
            content = transformer.read_destination_file('text', groups: :text)
            content = content.gsub('Hello', 'Goodbye')
            transformer.write_destination_file(file, content)
          end
        RUBY

        write_file('text.bade', <<~BADE)
          p Hello world
        BADE

        write_file('book.bookspec', <<~RUBY)
          Epuber::Book.new do |book|
            book.title = 'test'
            book.author = 'test test'

            book.use 'after_all_text_files.rb'

            book.toc do |toc|
              toc.file 'text'
            end
          end
        RUBY

        # Act
        Epuber::Command.run(%w[build])

        # Assert
        expect(File.read('.epuber/build/OEBPS/text.xhtml')).to include(<<~HTML)
          <p>Goodbye world</p>
        HTML
      end
    end
  end
end
