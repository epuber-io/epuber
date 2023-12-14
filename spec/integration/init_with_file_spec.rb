# frozen_string_literal: true

require_relative '../spec_helper'

module Epuber
  describe 'init (with file)' do
    include_context 'with temp dir'

    it 'can init project with file' do
      epub_filepath = File.join(__dir__, '..', 'fixtures', 'childrens-media-query.epub')
      Epuber::Command.run(%w[from-file] + [epub_filepath])

      expect(File).to exist('childrens-media-query.bookspec')
      expect(File.read('childrens-media-query.bookspec')).to eq <<~RUBY
        Epuber::Book.new do |book|
          book.title = "Abroad"
          book.authors = [
            "Thomas Crane",
            { name: "Ellen Elizabeth Houghton", role: "ill" },
          ]

          book.identifier = "urn:uuid:12C1DF3E-DF35-4FCF-918B-643FF15A7870"
          book.language = "en"
          book.published = "1882"
          book.publisher = "London ; Belfast ; New York : Marcus Ward & Co."

          book.toc do |toc, target|
            toc.file "childrens-book-page", "Page"
          end
        end
      RUBY

      # rest of files
      expect(File).to exist('childrens-book-flowers.jpg')
      expect(File).to exist('childrens-book-page.xhtml')
      expect(File).to exist('childrens-book-style.css')
      expect(File).to exist('childrens-book-swans.jpg')
      expect(File).to exist('small-screen.css')
      expect(File).not_to exist('toc.ncx')
      expect(File).not_to exist('toc.xhtml')
    end
  end
end
