# frozen_string_literal: true

require_relative '../../spec_helper'

module Epuber
  module DSL
    class TestTreeObject < TreeObject
      attribute :with_default_value,
                inherited: true,
                required: true,
                default_value: ''

      attribute :default_convert,
                inherited: true,
                required: true,
                default_value: 1,
                auto_convert: { [Float, Integer] => String }
    end

    describe TreeObject do
      before do
        @root = TestTreeObject.new
        @item1 = @root.create_child_item do |item|
          @item2 = item.create_child_item do |item2|
            @item3 = item2.create_child_item do |item3|
              @item4 = item3.create_child_item do |item4|
                @item5 = item4.create_child_item do |item5|
                  @item6 = item5.create_child_item do |item6|
                    @item7 = item6.create_child_item
                  end
                end
              end
            end
          end
        end
      end

      context 'flat child items' do
        it 'creates array of all sub_items' do
          child_items = @root.flat_sub_items
          expect(child_items.count).to eq(7)
        end
      end

      context 'default values' do
        it 'set value to root can be read by child' do
          @root.with_default_value = '1'
          expect(@item1.with_default_value).to eq '1'
          expect(@item7.with_default_value).to eq '1'
        end

        it 'set value to subitem can be read by child' do
          @item2.with_default_value = '1'

          expect(@item1.with_default_value).to eq ''
          expect(@item2.with_default_value).to eq '1'
          expect(@item3.with_default_value).to eq '1'
        end

        it 'converts the default value if needed' do
          expect(@root.default_convert).to eq '1'
        end
      end
    end
  end
end
