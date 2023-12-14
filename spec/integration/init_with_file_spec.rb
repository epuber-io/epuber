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

    it 'can init project with EPUB 2 file' do
      epub_filepath = File.join(__dir__, '..', 'fixtures', 'testing_book1-copyright.epub')
      Epuber::Command.run(%w[from-file] + [epub_filepath])

      expect(File).to exist('testing_book1-copyright.bookspec')
      expect(File.read('testing_book1-copyright.bookspec')).to eq <<~RUBY
        Epuber::Book.new do |book|
          book.title = "Testing Book Title"
          book.author = "Roman Kříž"

          book.isbn = "123-45-67890-12-1"
          # alternate identifier found from original EPUB file (Epuber supports only one identifier)
          # book.identifier = "urn:uuid:7d8273b5-70d4-4e8d-9b20-32fe23f1bbd4"
          book.language = "cs"
          book.published = "2016-10-09"
          book.publisher = "Jan Melvil Inc."

          book.cover_image = "images/cover"

          book.toc do |toc, target|
            toc.file "text/social_drm", "Social DRM"
            toc.file "text/copyright"
          end
        end
      RUBY

      # rest of files
      expect(File).to exist('text/social_drm.xhtml')
      expect(File).to exist('text/copyright.xhtml')
      expect(File).to exist('styles/testing_book.css')
      expect(File).to exist('images/cover.jpg')
      expect(File).to exist('fonts/Georgia/Georgia-Regular.ttf')
      expect(File).to exist('fonts/OpenSans/OpenSans-Regular.ttf')
    end
  end
end
