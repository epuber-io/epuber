# frozen_string_literal: true

require_relative '../spec_helper'

module Epuber
  describe 'init (with file)' do
    include_context 'with temp dir'

    it 'can init project with file' do
      epub_filepath = File.join(__dir__, '..', 'fixtures', 'childrens-media-query.epub')

      # Act
      Epuber::Command.run(%w[from-file] + [epub_filepath])

      # Assert
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
      expect(File.size('childrens-book-flowers.jpg')).to eq 17_094
      expect(File).to exist('childrens-book-page.xhtml')
      expect(File).to exist('childrens-book-style.css')
      expect(File).to exist('childrens-book-swans.jpg')
      expect(File).to exist('small-screen.css')
      expect(File).not_to exist('toc.ncx')
      expect(File).not_to exist('toc.xhtml')
    end

    it 'can init project with EPUB 2 file' do
      epub_filepath = File.join(__dir__, '..', 'fixtures', 'testing_book1-copyright.epub')

      # Act
      Epuber::Command.run(%w[from-file] + [epub_filepath])

      # Assert
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
            toc.file "text/copyright", :landmark_copyright
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

    it 'can deobfuscate files' do
      epub_filepath = File.join(__dir__, '..', 'fixtures', 'wasteland-otf-obf.epub')

      # Act
      Epuber::Command.run(%w[from-file] + [epub_filepath])

      # Assert
      # following values were manually checked
      expect(Digest::MD5.file('OldStandard-Bold.obf.otf')).to eq '9d814cc771da428de00f001351aa61e9'
      expect(Digest::MD5.file('OldStandard-Italic.obf.otf')).to eq 'd9c5ff1299294ddd08ffe329c46dcd09'
      expect(Digest::MD5.file('OldStandard-Regular.obf.otf')).to eq '74b70d8fb0dde57b8411d75f2e6eee21'
    end

    it 'prints some information to console' do
      epub_filepath = File.join(__dir__, '..', 'fixtures', 'childrens-media-query.epub')

      message = <<~TEXT.rstrip
        📖 Loading EPUB file #{__dir__}/../fixtures/childrens-media-query.epub
          Parsing OPF file at EPUB/content.opf
          Generating bookspec file
          Exporting childrens-book-style.css (from EPUB/childrens-book-style.css)
          Exporting small-screen.css (from EPUB/small-screen.css)
          Exporting childrens-book-flowers.jpg (from EPUB/childrens-book-flowers.jpg)
          Exporting childrens-book-swans.jpg (from EPUB/childrens-book-swans.jpg)
          Exporting childrens-book-page.xhtml (from EPUB/childrens-book-page.xhtml)
          Skipping toc.ncx (ncx file)
          Skipping toc.xhtml (not in spine)

        <green:start>🎉 Project initialized.
        Please review generated childrens-media-query.bookspec file and start using Epuber.

        For more information about Epuber, please visit https://github.com/epuber-io/epuber/tree/master/docs.<color-end>
      TEXT

      # Act
      Epuber::Command.run(%w[from-file] + [epub_filepath] + ['--ansi'])

      # Assert
      expect(UI.logger.formatted_messages).to eq message
    end
  end
end
