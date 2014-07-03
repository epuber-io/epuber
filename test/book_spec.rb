require_relative '../lib/epuber/book'

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

			expect(book.author).to be_a NormalContributor
			expect(book.author.first_name).to eq 'Abc'
			expect(book.author.last_name).to eq 'def'

			expect(book.publisher).to eq 'AAABBB'

			expect(book.language).to eq 'cs'

			expect(book.print_isbn).to eq '978-80-87270-98-0'
			expect(book.isbn).to eq '978-80-87270-98-2'
		end


		it 'author is required' do
			expect {
				book = Book.new do |b|
					b.title    = 'Práce na dálku'
					b.subtitle = 'Abc'
				end

				book.validate
			}.to raise_error
		end

		it 'title is required' do

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

		it 'block is optional, you can build whatever you like' do
			expect {
				Book.new
			}.to_not raise_error
		end
	end
end
