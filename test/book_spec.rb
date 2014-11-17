require_relative '../lib/epuber/book'
require 'rspec/collection_matchers'

module Epuber
	describe Book do

		before do
			@book = Book.new do |book|
				book.title    = 'Práce na dálku'
				book.subtitle = 'Abc'

				book.author = {
					:first_name => 'Abc',
					:last_name  => 'def'
				}

				book.publisher = 'AAABBB'
				book.language = 'cs'
				book.isbn = '978-80-87270-98-2'
				book.print_isbn = '978-80-87270-98-0'
			end
		end

		it 'should parse simple book' do
			book = @book

			expect(book.title).to eq 'Práce na dálku'
			expect(book.subtitle).to eq 'Abc'

			expect(book.publisher).to eq 'AAABBB'

			expect(book.language).to eq 'cs'

			expect(book.print_isbn).to eq '978-80-87270-98-0'
			expect(book.isbn).to eq '978-80-87270-98-2'
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

					expect {
						book.validate
					}.to raise_error
				end

				it 'supports array' do
					book = Book.new do |b|
						b.title    = 'Práce na dálku'
						b.subtitle = 'Abc'
						b.authors = [
							'Abc def'
						]
					end

					expect {
						book.validate
					}.to_not raise_error

					expect(book.authors).to contain_exactly(a_kind_of NormalContributor)
				end
			end

			it '#title is required' do
				book = Book.new do |b|
					b.subtitle = 'Abc'

					b.author = {
						:first_name => 'Abc',
						:last_name  => 'def'
					}
				end

				expect {
					book.validate
				}.to raise_error
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
		end

		it 'block is optional, you can build whatever you like' do
			expect {
				Book.new
			}.to_not raise_error
		end

		it  'can parse from string' do
			string = 	<<-END_BOOK
							Epuber::Book.new do |book|

								book.title = 'Práce na dálku'
								book.subtitle = 'Zn.: Kancelář zbytečná'

								book.author = 'Jason Fried'

							end
						END_BOOK

			book = Book.from_string(string)

			expect(book).to be_a Book

			expect {
				book.validate
			}.to_not raise_error
		end

		context 'targets' do
			it 'there is always at least one target' do
				expect(@book.targets.length).to eq 1
			end

			it 'can add target' do
				@book.target :ibooks do |ibooks|
					ibooks.isbn = 'abcd-1234'
				end

				targets = @book.targets
				expect(targets.length).to eq 1

				ibooks_target = targets[0]
				expect(ibooks_target.isbn).to eq 'abcd-1234'
			end

			it 'can suppports nested targets' do
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
		end

		context 'toc' do
			it 'can add toc items' do
				expect(@book.root_toc.child_items.length).to eq 0

				@book.toc do |toc|
					toc.file 'ch01', 'Chapter 1'
				end

				expect(@book.root_toc.child_items.length).to eq 1
			end
		end
	end
end
