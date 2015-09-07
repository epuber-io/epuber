# encoding: utf-8

require 'fakefs/spec_helpers'

require_relative '../spec_helper'

require 'epuber/book'
require 'epuber/compiler'




module Epuber
  class Compiler

    describe FileFinder do
      include FakeFS::SpecHelpers

      it 'stores info from init' do
        finder = FileFinder.new('dasdasas')
        expect(finder.source_path).to eq 'dasdasas'
      end

      it 'can find file in root folder' do
        FileUtils.touch(['a.xhtml', 'b.xhtml'])

        finder = FileFinder.new('.')
        files = finder.find_files('*.xhtml')
        expect(files.count).to eq 2
      end

      it 'can find file in root folder with group filtering' do
        FileUtils.touch(['c.xhtml', 'd.css'])

        finder = FileFinder.new('.')
        files = finder.find_files('*', :text)
        expect(files.count).to eq 1
        expect(files.first).to eq 'c.xhtml'
      end

      it 'can find file in root folder with group filtering' do
        FileUtils.touch(['c.xhtml', 'd.css', 'abc.txt'])

        finder = FileFinder.new('.')
        files = finder.find_files('*', [:text, :style])
        expect(files.count).to eq 2
        expect(files).to eq ['c.xhtml', 'd.css']
      end

      it 'crashes when unknown group name' do
        FileUtils.touch(['c.xhtml', 'd.css', 'abc.txt'])

        finder = FileFinder.new('.')

        expect {
          finder.find_files('*', :baf)
        }.to raise_error ::StandardError
      end
    end

  end
end
