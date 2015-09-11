# encoding: utf-8

require 'fakefs/spec_helpers'

require_relative '../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_finders/imaginary'




module Epuber
  class Compiler
    module FileFinders

      describe Imaginary do
        it 'support splitting path into components' do
          comps = Imaginary.path_parts('some/path/is/awesome/file.txt')
          expect(comps).to eq %w(some path is awesome file.txt)
        end

        it 'supports adding file' do
          finder = Imaginary.new('/')
          finder.add_file('abc.txt')

          expected = Imaginary::DirEntry.new('/')
          expected['abc.txt'] = 'abc.txt'

          expect(finder.root).to eq expected
        end

        it 'supports adding nested file' do
          finder = Imaginary.new('/')
          finder.add_file('some/path/abc.txt')

          expected = Imaginary::DirEntry.new('/')
          expected['some'] = Imaginary::DirEntry.new('some')
          expected['some']['path'] = Imaginary::DirEntry.new('path')
          expected['some']['path']['abc.txt'] = Imaginary::FileEntry.new('abc.txt', 'some/path/abc.txt')

          expect(finder.root).to eq expected
        end

        it 'can find file in root folder' do
          finder = Imaginary.new('/')
          finder.add_file('abc.txt')

          path = finder.find_files('abc.txt')
          expect(path).to eq ['abc.txt']
        end

        it 'can find file in specific context_path' do
          finder = Imaginary.new('/')
          finder.add_file('folder/baf/abc.txt')

          path = finder.find_files('abc.txt', context_path: 'folder/baf')
          expect(path).to eq ['abc.txt']
        end

      end
    end
  end
end
