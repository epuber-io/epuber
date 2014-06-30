
require_relative '../lib/epuber/book'

module Epuber
	describe Book do

		it 'should parse simple book' do
			book = Book.new do |b|
				b.title = 'A'
				b.subtitle = 'Abc'
				b.author = { :first_name => 'Abc', :last_name => 'def' }
			end

			expect(book.title).to eq('A')
			expect(book.subtitle).to eq('Abc')

			expect(book.author).to be_a(NormalContributor)
			expect(book.author.first_name).to eq('Abc')
			expect(book.author.last_name).to eq('def')
		end
	end
end
