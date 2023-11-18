# frozen_string_literal: true

module Epuber
  describe Compiler do
    before do
      @prev_dir = Dir.pwd

      @tmp_dir = Dir.mktmpdir
      Dir.chdir(@tmp_dir)

      Config.clear_instance!
    end

    after do
      Dir.chdir(@prev_dir)

      FileUtils.remove_entry(@tmp_dir)
      Config.clear_instance!
    end

    describe 'bookspec validation' do
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
          Epuber::Command.run(%w[build])
        end.to raise_error(SystemExit)
      end
    end
  end
end
