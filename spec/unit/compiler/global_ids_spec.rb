# frozen_string_literal: true

module Epuber
  describe Compiler do # rubocop:disable RSpec/FilePath
    describe 'global ids' do
      include_context 'with temp dir'

      it 'can link global ids' do
        write_file('text/file1.xhtml', <<~HTML)
          <div>
            <p><a href="$some_id">abc</a></p>
            <p><a href="#other_id">abc</a></p>
          </div>
        HTML

        write_file('text/file2.xhtml', <<~HTML)
          <div>
            <p id="$some_id">abc</p>
            <p id="other_id">abc2</p>
          </div>
        HTML

        write_file('book.bookspec', <<~RUBY)
          Epuber::Book.new do |book|
            book.title = 'test'
            book.author = 'test test'
            book.isbn = '123'
            book.target :ibooks

            book.toc do |toc, target|
              toc.file 'text/file1'
              toc.file 'text/file2'
            end
          end
        RUBY

        expect do
          Epuber::Command.run(%w[build ibooks])
        end.to output(/.*/).to_stdout

        expect(load_xhtml('.epuber/build/ibooks/OEBPS/text/file1.xhtml').at_css('body div').to_s).to eql <<~HTML.rstrip
          <div>
            <p><a href="file2.xhtml#some_id">abc</a></p>
            <p><a href="#other_id">abc</a></p>
          </div>
        HTML
        expect(load_xhtml('.epuber/build/ibooks/OEBPS/text/file2.xhtml').at_css('body div').to_s).to eql <<~HTML.rstrip
          <div>
            <p id="some_id">abc</p>
            <p id="other_id">abc2</p>
          </div>
        HTML
      end

      it 'can handle missing id anchor' do
        write_file('text/file1.xhtml', <<~HTML)
          <div>
            <p><a href="$some_id">abc</a></p>
          </div>
        HTML

        write_file('text/file2.xhtml', <<~HTML)
          <div>
            <p id="some_id">abc</p>
          </div>
        HTML

        write_file('book.bookspec', <<~RUBY)
          Epuber::Book.new do |book|
            book.title = 'test'
            book.author = 'test test'
            book.isbn = '123'
            book.target :ibooks

            book.toc do |toc, target|
              toc.file 'text/file1'
              toc.file 'text/file2'
            end
          end
        RUBY

        expect do
          Epuber::Command.run(%w[build ibooks])
        end.to output(%r{Can't find global id 'some_id' from link in file text/file1.xhtml}).to_stdout
      end
    end
  end
end
