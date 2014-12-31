# encoding: utf-8

require_relative 'helpers/spec_helper'

require_relative '../lib/Epuber/book/target'

module Epuber
  describe Target do
    before do
      @root = Target.new('root')
      @root.isbn = '123-145'
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

    context '#is_ibooks?' do
      it 'default is false' do
        expect(@root.is_ibooks?).to be_falsey
      end

      it 'is true when the name is ibooks' do
        target = Target.new('ibooks')
        expect(target.is_ibooks?).to be_truthy
      end

      it 'is true when the attribute is set to true' do
        @root.is_ibooks = true
        expect(@root.is_ibooks?).to be_truthy
      end

      it 'is false when the attribute is set to false' do
        @root.is_ibooks = false
        expect(@root.is_ibooks?).to be_falsey
      end

      it 'is false when the attribute is set to false even when the name is ibooks' do
        target = Target.new('ibooks')
        target.is_ibooks = false
        expect(target.is_ibooks?).to be_falsey
      end
    end
  end
end
