require_relative '../lib/epuber/book'

module Epuber
	describe Book do

		before do
			@book = Book.new do |b|
				b.title    = 'Práce na dálku'
				b.subtitle = 'Abc'

				b.author = {
					:first_name => 'Abc',
					:last_name  => 'def'
				}

				b.publisher = 'AAABBB'
			end
		end

		it 'should parse simple book' do

			book = @book

			expect(book.title).to eq 'Práce na dálku'
			expect(book.subtitle).to eq('Abc')

			expect(book.author).to be_a(NormalContributor)
			expect(book.author.first_name).to eq('Abc')
			expect(book.author.last_name).to eq('def')

			expect(book.publisher).to eq('AAABBB')
		end


		it 'author is required' do
			expect {
				book = Book.new do |b|
					b.title    = 'Práce na dálku'
					b.subtitle = 'Abc'
				end
			}.to raise_error
		end
	end
end
