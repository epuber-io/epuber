require 'rspec'

require_relative '../lib/epuber/toc_item'

module Epuber
	describe TocItem do

		before do
			@root           = TocItem.new
			@root.title     = 'Section 1'
			@root.file_path = 's01'
		end

		it 'store information' do
			expect(@root.title).to eq 'Section 1'
			expect(@root.file_path).to eq 's01'
		end

		context 'sub items creating' do

			context '.file' do
				it 'should add item' do
					expect(@root.child_items.length).to be 0

					@root.file 'ch01', 'Chapter 1'

					expect(@root.child_items.length).to be 1
				end

				it 'store information after creating sub item' do
					sub_item = @root.file('ch01', 'Chapter 1')

					expect(sub_item.title).to eq 'Chapter 1'
					expect(sub_item.file_path).to eq 'ch01'
				end

				it 'child items inherit file_path' do
					sub_item = @root.file(nil, 'Chapter 1')

					expect(sub_item.file_path).to eq 's01'
				end
			end

			it 'create sub item (abstract with no file)' do
				sub_item = @root.item('Chapter 2')

				expect(sub_item.title).to eq 'Chapter 2'
				expect(sub_item.file_path).to eq 's01' # file path should be inherited
			end

			context 'options' do
				it 'parse simple symbol' do
					sub_item = @root.item('', :landmark, :landmark_2)
					expect(sub_item.options).to eq [:landmark, :landmark_2]
				end

				it 'parse simple key value' do
					sub_item = @root.item('', :key => 1, :key_2 => 2)
					expect(sub_item.options).to eq [{ :key => 1 }, { :key_2 => 2}]
				end

				it 'parse multiple items' do
					sub_item = @root.item('', :landmark, :landmark_2, :key => 1, :key_2 => 2)
					expect(sub_item.options).to eq [:landmark, :landmark_2, {:key => 1}, {:key_2 => 2}]
				end
			end
		end


		# TODO options
	end
end
