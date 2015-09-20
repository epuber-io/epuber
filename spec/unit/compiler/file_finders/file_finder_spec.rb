# encoding: utf-8

require_relative '../../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'




module Epuber
  class Compiler

    describe FileFinders::Normal do
      include FakeFS::SpecHelpers

      before do
        @finder = FileFinders::Normal.new('.')
      end


      it 'stores info from init' do
        finder = FileFinders::Normal.new('dasdasas')
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

        it 'finds file without specifying extension' do
          FileUtils.touch(['c.xhtml', 'd.css', 'abc.txt'])

          files = @finder.find_files('c')
          expect(files).to contain_exactly 'c.xhtml'
        end
      end

      context '#find_files cases with context_path' do
        it 'can find files in context folder' do
          FileUtils.mkdir_p('abc')
          FileUtils.touch(['abc/file1.xhtml', 'abc/file2.xhtml', 'abc/file3.xhtml'])

          files = @finder.find_files('*.xhtml', context_path: 'abc')
          expect(files).to contain_exactly 'file1.xhtml', 'file2.xhtml', 'file3.xhtml'
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
          expect(files).to contain_exactly '../file1.xhtml', '../file2.xhtml', '../file3.xhtml'
        end

        it 'returns relative path to context path' do
          FileUtils.mkdir_p('abc/def/ghi')
          FileUtils.touch(['file1.xhtml', 'file2.xhtml', 'file3.xhtml'])

          files = @finder.find_files('*.xhtml', context_path: 'abc/def/ghi')
          expect(files).to contain_exactly '../../../file1.xhtml', '../../../file2.xhtml', '../../../file3.xhtml'
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
          expect(files).to contain_exactly 'dir_1/one.xhtml', 'dir_1/dir_11/dir_111/one.xhtml'

          files = @finder.find_all('*.md')
          expect(files).to contain_exactly 'dir_2/baf.md', 'dir_3/abc_md.md'

          files = @finder.find_all('*.stylus', groups: :style)
          expect(files.size).to eq 0
        end

        it 'can find files without specifying extension' do
          FileUtils.mkdir_p('dir_1/dir_11/dir_111')
          FileUtils.mkdir_p('dir_2')
          FileUtils.mkdir_p('dir_3')
          FileUtils.mkdir_p('.git')

          FileUtils.touch(['dir_1/one.xhtml', 'dir_1/two.xhtml', 'dir_1/three.css'])
          FileUtils.touch(['dir_1/dir_11/dir_111/one.xhtml', 'dir_1/dir_11/dir_111/two.xhtml', 'dir_1/dir_11/dir_111/three.css'])
          FileUtils.touch(['dir_2/fif.stylus', 'dir_2/baf.md', 'dir_2/hi.css', 'dir_2/one.bade'])
          FileUtils.touch(['dir_3/abc.xhtml', 'dir_3/abc_md.md', 'dir_3/abc.txt'])
          FileUtils.touch(['.gitignore', 'README.txt'])

          files = @finder.find_all('one', groups: :text)
          expect(files).to contain_exactly 'dir_1/one.xhtml', 'dir_1/dir_11/dir_111/one.xhtml', 'dir_2/one.bade'
        end
      end

      context '#find_file' do
        it 'can find exactly one file' do
          FileUtils.touch(['c.xhtml', 'd.css', 'abc.txt'])

          file = @finder.find_file('c')
          expect(file).to eq 'c.xhtml'
        end

        it "raises error when no file couldn't be found" do
          FileUtils.touch(['c.xhtml', 'd.css', 'abc.txt'])

          expect {
            @finder.find_file('baf')
          }.to raise_error FileFinders::FileNotFoundError
        end

        it "raises error when no file couldn't be found" do
          FileUtils.touch(['a.xhtml', 'b.xhtml'])

          expect {
            @finder.find_file('*.xhtml')
          }.to raise_error FileFinders::MultipleFilesFoundError
        end

        it 'returns relative path to context path' do
          FileUtils.mkdir_p('abc/def/ghi')
          FileUtils.touch(['file1.xhtml', 'file2.xhtml', 'file3.xhtml'])

          files = @finder.find_file('file1', context_path: 'abc/def/ghi')
          expect(files).to eq '../../../file1.xhtml'
        end

        it 'can find file even the path contains fragment' do
          FileUtils.touch(['a.xhtml', 'b.xhtml'])

          file = @finder.find_file('a#baf')
          expect(file).to eq 'a.xhtml'
        end
      end

      context '#ignored_patterns' do
        it 'support ignoring patterns' do
          @finder.ignored_patterns << '/abc/**'

          FileUtils.mkdir_p('/abc')
          FileUtils.touch(['/abc/some_file.xhtml'])

          files = @finder.find_all('*.xhtml')
          expect(files.size).to eq 0

          FileUtils.mkdir_p('/def')
          FileUtils.touch(['/def/some_file.xhtml'])

          files = @finder.find_all('*.xhtml')
          expect(files).to contain_exactly 'def/some_file.xhtml'
        end
      end

      context '.group_filter_paths' do
        it 'returns the same array for nil groups' do
          input = %w(some/path/abc.txt some/path/abc2.txt a.txt)
          output = FileFinders::Abstract.group_filter_paths(input, nil)
          expect(output).to be input
        end

        it 'returns filtered array for text groups' do
          input = %w(abc.xhtml a.png t.txt e.html)
          output = FileFinders::Abstract.group_filter_paths(input, :text)
          expect(output).to eq %w(abc.xhtml e.html)
        end

        it 'returns filtered array for text and image groups' do
          input = %w(abc.xhtml a.png t.txt e.html font.otf)
          output = FileFinders::Abstract.group_filter_paths(input, [:text, :image])
          expect(output).to eq %w(abc.xhtml a.png e.html)
        end
      end
    end

    # TODO: can find files from super folder

  end
end
