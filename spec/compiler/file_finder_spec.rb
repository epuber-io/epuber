# encoding: utf-8

require 'fakefs/spec_helpers'

require_relative '../spec_helper'

require 'epuber/book'
require 'epuber/compiler'




module Epuber
  class Compiler

    describe FileFinder do
      include FakeFS::SpecHelpers

      before do
        @finder = FileFinder.new('.')
      end


      it 'stores info from init' do
        finder = FileFinder.new('dasdasas')
        expect(finder.source_path).to eq 'dasdasas'
      end

      context '#find_files' do
        it 'can find file in root folder' do
          FileUtils.touch(['a.xhtml', 'b.xhtml'])

          files = @finder.find_files('*.xhtml')
          expect(files.count).to eq 2
        end

        it 'can find file in root folder with group filtering' do
          FileUtils.touch(['c.xhtml', 'd.css'])

          files = @finder.find_files('*', groups: :text)
          expect(files.count).to eq 1
          expect(files.first).to eq 'c.xhtml'
        end

        it 'can find file in root folder with groups filtering' do
          FileUtils.touch(['c.xhtml', 'd.css', 'abc.txt'])

          files = @finder.find_files('*', groups: [:text, :style])
          expect(files.count).to eq 2
          expect(files).to eq ['c.xhtml', 'd.css']
        end

        it 'raises exception when unknown group name' do
          FileUtils.touch(['c.xhtml', 'd.css', 'abc.txt'])

          expect {
            @finder.find_files('*', groups: :baf)
          }.to raise_error ::StandardError
        end
      end

      context '#find_files cases with context_path' do
        it 'can find files in context folder' do
          FileUtils.mkdir_p('abc')
          FileUtils.touch(['abc/file1.xhtml', 'abc/file2.xhtml', 'abc/file3.xhtml'])

          files = @finder.find_files('*.xhtml', context_path: 'abc')
          expect(files.size).to eq 3
        end

        it 'can find files in nested folder' do
          FileUtils.mkdir_p('abc')
          FileUtils.touch(['abc/file1.xhtml', 'abc/file2.xhtml', 'abc/file3.xhtml'])

          files = @finder.find_files('*.xhtml')
          expect(files.size).to eq 3
        end

        it "can't find files in nested folder when search_everywhere == false" do
          FileUtils.mkdir_p('abc')
          FileUtils.touch(['abc/file1.xhtml', 'abc/file2.xhtml', 'abc/file3.xhtml'])

          files = @finder.find_files('*.xhtml', search_everywhere: false)
          expect(files.size).to eq 0
        end

        it 'can find files in root folder when context path is different' do
          FileUtils.mkdir_p('abc')
          FileUtils.touch(['file1.xhtml', 'file2.xhtml', 'file3.xhtml'])

          files = @finder.find_files('*.xhtml', context_path: 'abc')
          expect(files.size).to eq 3
        end
      end
    end

  end
end
