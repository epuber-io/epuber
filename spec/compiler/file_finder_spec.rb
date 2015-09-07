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
          expect(files).to include 'file1.xhtml', 'file2.xhtml', 'file3.xhtml'
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

      context '#find_all' do
        it 'can find all files in project' do
          FileUtils.mkdir_p('dir_1/dir_11/dir_111')
          FileUtils.mkdir_p('dir_2')
          FileUtils.mkdir_p('dir_3')
          FileUtils.mkdir_p('.git')

          FileUtils.touch(['dir_1/one.xhtml', 'dir_1/two.xhtml', 'dir_1/three.css'])
          FileUtils.touch(['dir_1/dir_11/dir_111/one.xhtml', 'dir_1/dir_11/dir_111/two.xhtml', 'dir_1/dir_11/dir_111/three.css'])
          FileUtils.touch(['dir_2/fif.stylus', 'dir_2/baf.md', 'dir_2/hi.css'])
          FileUtils.touch(['dir_3/abc.xhtml', 'dir_3/abc_md.md', 'dir_3/abc.txt'])
          FileUtils.touch(['.gitignore', 'README.txt'])

          files = @finder.find_all('one.xhtml', groups: :text)
          expect(files).to include 'dir_1/one.xhtml', 'dir_1/dir_11/dir_111/one.xhtml'

          files = @finder.find_all('*.md')
          expect(files).to include 'dir_2/baf.md', 'dir_3/abc_md.md'

          files = @finder.find_all('*.stylus', groups: :style)
          expect(files.size).to eq 0
        end
      end
    end

    # TODO: can find files without specified extension
    # TODO: can find files from super folder

  end
end
