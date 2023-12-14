# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative 'epub3_fixtures'
require_relative 'epub2_fixtures'

require 'epuber/from_file/opf_file'
require 'epuber/from_file/nav_file'
require 'epuber/from_file/bookspec_generator'

module Epuber
  describe BookspecGenerator do
    describe 'epub3' do
      it 'can generate book title' do
        sut = described_class.new(OpfFile.new(EPUB3_OPF), NavFile.new(EPUB3_NAV, :xhtml))

        res = sut.generate_bookspec

        expect(res).to eq <<~RUBY
          Epuber::Book.new do |book|
            book.title = "Abroad"
            book.authors = [
              "Thomas Crane",
              { name: "Ellen Elizabeth Houghton", role: "ill" },
            ]

            book.identifier = "urn:uuid:12C1DF3E-DF35-4FCF-918B-643FF15A7870"
            book.language = "en"
            book.published = "1882-01-01"
            book.publisher = "London ; Belfast ; New York : Marcus Ward & Co."

            book.cover_image = "childrens-book-flowers"

            book.toc do |toc, target|
              toc.file "childrens-book-page1", "Page 1" do
                toc.file "childrens-book-page1#page_1_1", "Page 1.1"
                toc.file "childrens-book-page1#page_1_2", "Page 1.2"
                toc.file "childrens-book-page1#page_1_3", "Page 1.3"
              end
              toc.file "childrens-book-page2", "Page 2" do
                toc.file "childrens-book-page2_sub1", "Page 2.1"
                toc.file "childrens-book-page2_sub2", "Page 2.2"
                toc.file "childrens-book-page2_sub3", "Page 2.3"
              end
              toc.file "childrens-book-page3", "Page 3"
              toc.file "childrens-book-page4", "Page 4"
            end
          end
        RUBY
      end

      it 'can be parsed by Epuber::Book' do
        sut = described_class.new(OpfFile.new(EPUB3_OPF), NavFile.new(EPUB3_NAV, :xhtml))

        res = sut.generate_bookspec

        expect do
          book = Book.from_string(res)
          book.validate
        end.not_to raise_error
      end
    end

    describe 'epub2' do
      it 'can generate book title' do
        sut = described_class.new(OpfFile.new(EPUB2_OPF), NavFile.new(EPUB2_NCX, NavFile::MODE_NCX))

        res = sut.generate_bookspec

        expect(res).to eq <<~RUBY
          Epuber::Book.new do |book|
            book.title = "Abroad"
            book.authors = [
              "Thomas Crane",
              { name: "Ellen Elizabeth Houghton", role: "ill" },
            ]

            book.identifier = "urn:uuid:12C1DF3E-DF35-4FCF-918B-643FF15A7870"
            book.language = "en"
            book.published = "1882-01-01"
            book.publisher = "London ; Belfast ; New York : Marcus Ward & Co."

            book.cover_image = "childrens-book-flowers"

            book.toc do |toc, target|
              toc.file "childrens-book-page1", "Page 1" do
                toc.file "childrens-book-page1#page_1_1", "Page 1.1"
                toc.file "childrens-book-page1#page_1_2", "Page 1.2"
                toc.file "childrens-book-page1#page_1_3", "Page 1.3"
              end
              toc.file "childrens-book-page2", "Page 2" do
                toc.file "childrens-book-page2_sub1", "Page 2.1"
                toc.file "childrens-book-page2_sub2", "Page 2.2"
                toc.file "childrens-book-page2_sub3", "Page 2.3"
              end
              toc.file "childrens-book-page3", "Page 3"
              toc.file "childrens-book-page4", "Page 4"
            end
          end
        RUBY
      end

      it 'can be parsed by Epuber::Book' do
        sut = described_class.new(OpfFile.new(EPUB2_OPF), NavFile.new(EPUB2_NCX, NavFile::MODE_NCX))

        res = sut.generate_bookspec

        expect do
          book = Book.from_string(res)
          book.validate
        end.not_to raise_error
      end
    end
  end
end
