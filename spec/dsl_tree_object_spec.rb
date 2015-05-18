# encoding: utf-8

require_relative 'spec_helper'

module Epuber
  module DSL
    describe TreeObject do
      context 'flat child items' do

        root = nil
        before do
          root = TreeObject.new
          root.create_child_item do |item|
            item.create_child_item do |item2|
              item2.create_child_item do |item3|
                item3.create_child_item do |item4|
                  item4.create_child_item do |item5|
                    item5.create_child_item do |item6|
                      item6.create_child_item
                    end
                  end
                end
              end
            end
          end
        end

        it 'should create array of all sub_items' do
          child_items = root.flat_sub_items
          expect(child_items.count).to eq(7)
        end
      end
    end
  end
end
