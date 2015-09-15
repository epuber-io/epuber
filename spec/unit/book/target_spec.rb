# encoding: utf-8

require_relative '../../spec_helper'


module Epuber
  class Book
    describe Target do
      before do
        @book = Book.new
        @root = Target.new('root')
        @root.isbn = '123-145'
        @root.book = @book

        @child = Target.new(@root, 'child')
      end

      it 'store name' do
        expect(@root.name).to eq 'root'
        expect(@child.name).to eq 'child'
      end

      it 'store tree hierarchy' do
        expect(@child.parent.name).to eq 'root'

        expect(@child.parent).to eq @root
        expect(@root.sub_targets.length).to eq 1
      end

      it 'can create sub target' do
        new_child = @child.sub_target('sub_child')

        expect(new_child.parent).to eq @child
        expect(@child.sub_targets.length).to eq 1
      end

      it 'supports inherited values' do
        expect(@child.isbn).to eq @root.isbn
      end

      it 'inherited values specified in callee target are not ignored' do
        @child.isbn = '123'
        expect(@child.isbn).to eq '123'
      end

      context '#book' do
        it 'keep reference to book' do
          expect(@root.book).to eq @book
        end

        it 'traverse searching for book to parent' do
          expect(@child.book).to eq @book
        end
      end

      context '#add_const' do
        it 'supports adding one key with key, value way' do
          @root.add_const :key, 'value'
          expect(@root.constants).to eq({key: 'value'})
        end
        
        it 'supports adding one key with key: value way' do
          @root.add_const :key => 'value'
          @root.add_const key2: 'value'
          expect(@root.constants).to eq({key: 'value', key2: 'value'})
        end

        it 'supports adding multiple keys with key: value way' do
          @root.add_const key: 'value',
                          key2: 'value',
                          key3: 'value'
          expect(@root.constants).to eq({key: 'value', key2: 'value', key3: 'value'})
        end
      end

      context '#is_ibooks?' do
        it 'default is false' do
          expect(@root.ibooks?).to be_falsey
        end

        it 'is true when the name is ibooks' do
          target = Target.new('ibooks')
          expect(target.ibooks?).to be_truthy
        end

        it 'is true when the attribute is set to true' do
          @root.is_ibooks = true
          expect(@root.ibooks?).to be_truthy
        end

        it 'is false when the attribute is set to false' do
          @root.is_ibooks = false
          expect(@root.ibooks?).to be_falsey
        end

        it 'is false when the attribute is set to false even when the name is ibooks' do
          target = Target.new('ibooks')
          target.is_ibooks = false
          expect(target.ibooks?).to be_falsey
        end
      end
    end
  end
end
