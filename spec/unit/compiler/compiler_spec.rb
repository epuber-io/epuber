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

    describe 'global ids' do
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

        Epuber::Command.run(%w[build ibooks])

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
    end
  end
end
