# frozen_string_literal: true

require_relative '../../spec_helper'


module Epuber
  class Book
    describe Book do
      before do
        @book = Book.new do |book|
          book.title    = 'Práce na dálku'
          book.subtitle = 'Abc'

          book.author = {
            first_name: 'Abc',
            last_name: 'def',
          }

          book.publisher  = 'AAABBB'
          book.language   = 'cs'
          book.isbn       = '978-80-87270-98-2'
          book.print_isbn = '978-80-87270-98-0'
        end

        @target = @book.default_target
      end

      it 'should parse simple book and store all informations' do
        book = @book

        expect(book.title).to eq 'Práce na dálku'
        expect(book.subtitle).to eq 'Abc'

        expect(book.publisher).to eq 'AAABBB'

        expect(book.language).to eq 'cs'

        expect(book.print_isbn).to eq '978-80-87270-98-0'
        expect(book.isbn).to eq '978-80-87270-98-2'

        expect(@target).to_not be_nil
      end

      it 'has defaults' do
        book = Book.new
        expect(book.epub_version).to eq '3.0'
      end

      context 'attributes' do
        context '#authors, #author' do
          it 'automatically converts into NormalContributor' do
            book = @book
            expect(book.author).to be_a NormalContributor
            expect(book.author.first_name).to eq 'Abc'
            expect(book.author.last_name).to eq 'def'
          end

          it 'is required' do
            book = Book.new do |b|
              b.title    = 'Práce na dálku'
              b.subtitle = 'Abc'
            end

            expect { book.validate }.to raise_error ValidationError
          end

          it 'supports array' do
            book = Book.new do |b|
              b.title    = 'Práce na dálku'
              b.subtitle = 'Abc'
              b.authors  = ['Abc def']
            end

            expect { book.validate }.to_not raise_error

            expect(book.authors).to contain_exactly(a_kind_of(NormalContributor))
          end
        end

        it '#title is required' do
          book = Book.new do |b|
            b.subtitle = 'Abc'

            b.author = {
              first_name: 'Abc',
              last_name: 'def',
            }
          end

          expect { book.validate }.to raise_error ValidationError
        end

        context '#published' do
          it 'is automatically converted to date if needed' do
            @book.published = '2014-11-10'

            expect(@book.published).to eq Date.new(2014, 11, 10)
          end

          it 'can be set with normal Date' do
            @book.published = Date.new(2013, 11, 10)

            expect(@book.published).to eq Date.new(2013, 11, 10)
          end
        end

        it '#version is optional' do
          @book.version = '1.0.1'

          expect { @book.validate }.to_not raise_error
        end

        it '#is_ibooks is stored and optional' do
          @book.is_ibooks = true

          expect do
            @book.validate
          end.to_not raise_error
        end
      end

      it 'block is optional, you can build whatever you like' do
        expect { Book.new }.to_not raise_error
      end

      it 'can parse from string' do
        string = <<-END_BOOK
              Epuber::Book.new do |book|

                book.title = 'Práce na dálku'
                book.subtitle = 'Zn.: Kancelář zbytečná'

                book.author = 'Jason Fried'

              end
        END_BOOK

        book = Book.from_string(string)

        expect(book).to be_a Book

        expect { book.validate }.to_not raise_error
      end

      context 'targets' do
        it 'there is always at least one target' do
          expect(@book.all_targets.length).to eq 1
        end

        it 'can add target' do
          @book.target :ibooks do |ibooks|
            ibooks.isbn = 'abcd-1234'
          end

          targets = @book.all_targets
          expect(targets.length).to eq 1

          ibooks_target = targets[0]
          expect(ibooks_target.isbn).to eq 'abcd-1234'
        end

        it 'supports nested targets' do
          @book.isbn = 'abcd-1234'

          ibooks_target_sub = nil
          ibooks_target     = @book.target :ibooks do |ibooks|
            ibooks.epub_version = '3.0'

            ibooks_target_sub = ibooks.sub_target :ibooks_sub do |ibooks_sub|
              ibooks_sub.epub_version = '2.0'
            end
          end

          expect(ibooks_target.sub_targets.length).to eq 1
          expect(ibooks_target.epub_version).to eq '3.0'

          expect(ibooks_target_sub.isbn).to eq 'abcd-1234'
          expect(ibooks_target_sub.epub_version).to eq '2.0'
        end

        it 'there is reference to book from created target' do
          target = @book.target :some_target
          expect(target.book).to eq @book
        end

        it 'can create multiple targets at same time' do
          targets = @book.targets :target1, :target2, :target3
          expect(targets.count).to eq 3
        end

        it 'can create multiple targets at same time also with configure block' do
          targets = @book.targets :target1, :target2, :target3 do |t|
            t.add_const abc: 'some const'
          end

          expect(targets.count).to eq 3
          expect(targets.map { |t| t.constants[:abc] }).to contain_exactly 'some const', 'some const', 'some const'
        end
      end

      context 'toc' do
        it 'can add toc items' do
          expect(@target.root_toc.sub_items.length).to eq 0

          @book.toc do |toc|
            toc.file 'ch01', 'Chapter 1'
          end

          @book.finish_toc

          expect(@target.root_toc.sub_items.length).to eq 1
        end

        it 'can define landmarks' do
          @book.toc do |toc|
            toc.file 'ch01', 'Chapter 1', :landmarks_cover
            toc.file 'ch02', 'Chapter 2', :landmarks_start_page
          end

          @book.finish_toc

          ch1 = @target.root_toc.sub_items[0]
          expect(ch1.options).to contain_exactly(:landmarks_cover)

          ch2 = @target.root_toc.sub_items[1]
          expect(ch2.options).to contain_exactly(:landmarks_start_page)
        end

        it 'title of file is optional' do
          @book.toc do |toc|
            toc.file 'cover', :landmarks_cover
            toc.file 'ch01', 'Chapter 1', :landmarks_start_page
          end

          @book.finish_toc

          cover = @target.root_toc.sub_items[0]
          expect(cover.options).to contain_exactly(:landmarks_cover)
          expect(cover.title).to be_nil
          expect(cover.file_request).to eq 'cover'
        end

        it 'support for linear = false' do
          @book.toc do |toc|
            toc.file 'cover', linear: false
          end

          @book.finish_toc

          cover = @target.root_toc.sub_items[0]
          expect(cover.options).to contain_exactly(linear: false)
          expect(cover.title).to be_nil
          expect(cover.file_request).to eq 'cover'
        end

        it 'support options and linear = false together' do
          @book.toc do |toc|
            toc.file 'cover', :landmarks_cover, linear: false
          end

          @book.finish_toc

          cover = @target.root_toc.sub_items[0]
          expect(cover.options).to contain_exactly(:landmarks_cover, linear: false)
          expect(cover.title).to be_nil
          expect(cover.file_request).to eq 'cover'
        end
      end
    end
  end
end
