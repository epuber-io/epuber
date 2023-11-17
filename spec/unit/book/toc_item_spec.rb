# frozen_string_literal: true

require_relative '../../spec_helper'

require 'epuber/book/toc_item'

module Epuber
  class Book
    describe TocItem do
      before do
        @root          = TocItem.new
        @root.title    = 'Section 1'
        @root.file_request = 's01'
      end

      it 'store information' do
        expect(@root.title).to eq 'Section 1'
        expect(@root.file_request).to eq 's01'
      end

      context 'sub items creating' do
        context '.file' do
          it 'should add item' do
            expect(@root.sub_items.length).to be 0

            @root.file 'ch01', 'Chapter 1'

            expect(@root.sub_items.length).to be 1
          end

          it 'store information after creating sub item' do
            sub_item = @root.file('ch01', 'Chapter 1')

            expect(sub_item.title).to eq 'Chapter 1'
            expect(sub_item.file_request).to eq 'ch01'
          end

          it 'child items inherit file_request' do
            sub_item = @root.file(nil, 'Chapter 1')

            expect(sub_item.file_request).to eq 's01'
          end
        end

        it 'create sub item (abstract with no file)' do
          sub_item = @root.item('Chapter 2')

          expect(sub_item.title).to eq 'Chapter 2'
          expect(sub_item.file_request).to eq 's01' # file path should be inherited
        end

        context 'parsing and storing options' do
          it 'parse simple symbol' do
            sub_item = @root.item('', :landmark, :landmark_2)
            expect(sub_item.options).to eq %i[landmark landmark_2]
          end

          it 'parse simple key value' do
            sub_item = @root.item('', key: 1, key_2: 2)
            expect(sub_item.options).to eq [{ key: 1 }, { key_2: 2 }]
          end

          it 'parse multiple items' do
            sub_item = @root.item('', :landmark, :landmark_2, key: 1, key_2: 2)
            expect(sub_item.options).to eq [:landmark, :landmark_2, { key: 1 }, { key_2: 2 }]
          end
        end

        context '#full_source_pattern' do
          it 'returns the same pattern when pattern includes path' do
            expect(@root.full_source_pattern).to eq 's01'
            expect(@root.local_source_pattern).to eq 's01'
          end

          it 'returns composed pattern when child item have only fragment' do
            subitem = @root.file '#fragment'
            expect(subitem.full_source_pattern).to eq 's01#fragment'
            expect(subitem.local_source_pattern).to eq '#fragment'
          end

          it 'returns composed pattern when multiple children items have only fragment' do
            subitem = nil
            @root.file '#fragment' do
              @root.file '#fragment1' do
                @root.file '#fragment2' do
                  @root.file '#fragment3' do
                    @root.file '#fragment4' do
                      @root.file '#fragment5' do
                        @root.file '#fragment6' do |current_item|
                          subitem = current_item
                        end
                      end
                    end
                  end
                end
              end
            end

            expect(subitem.full_source_pattern).to eq 's01#fragment6'
            expect(subitem.local_source_pattern).to eq '#fragment6'
          end
        end
      end

      # TODO: nested creating
    end
  end
end
