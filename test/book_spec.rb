
require_relative '../lib/epuber/book'

module Epuber
	describe Book do

		it 'should parse simple book' do
			book = Book.new do |b|
				b.title = 'A'
				b.subtitle = 'Abc'
			end

			expect(book.title).to eq('A')
			expect(book.subtitle).to eq('Abc')
		end
	end
end
