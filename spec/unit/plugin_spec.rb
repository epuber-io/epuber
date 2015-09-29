# encoding: utf-8

require_relative '../spec_helper'

require 'epuber/plugin'


module Epuber


  describe Plugin do
    include FakeFS::SpecHelpers

    context 'init' do
      it 'can load from file' do
        FileUtils.touch('plugin.rb')

        expect {
          Plugin.new('plugin.rb')
        }.to_not raise_exception
      end

      it 'can load from empty folder' do
        FileUtils.mkdir_p('plugin')

        expect {
          Plugin.new('plugin')
        }.to_not raise_exception
      end

      it 'can load from empty folder' do
        FileUtils.mkdir_p('plugin')
        FileUtils.touch('plugin/plugin.rb')

        expect {
          Plugin.new('plugin')
        }.to_not raise_exception
      end

      it "raise exception when the file doesn't exist" do
        expect {
          Plugin.new('plugin.rb')
        }.to raise_exception LoadError
      end

      it "raise exception when the folder doesn't exist" do
        expect {
          Plugin.new('plugin/')
        }.to raise_exception LoadError
      end
    end
  end


end
