# frozen_string_literal: true

module Epuber
  describe Compiler do # rubocop:disable RSpec/FilePath
    describe 'bookspec validation' do
      include_context 'with temp dir'

      it 'can validate bookspec' do
        write_file('validate.rb', <<~RUBY)
          check :bookspec do |checker, book|
            checker.error('ISBN is invalid') if book.isbn == '123'
          end
        RUBY

        write_file('book.bookspec', <<~RUBY)
          Epuber::Book.new do |book|
            book.title = 'test'
            book.author = 'test test'
            book.isbn = '123'
            book.target :ibooks

            book.use 'validate.rb'
          end
        RUBY

        expect do
          Epuber::Command.run(%w[build --release])
        end.to raise_error(SystemExit)

        # Assert
        expect(UI.logger.formatted_messages).to include('ISBN is invalid')
      end
    end
  end
end
