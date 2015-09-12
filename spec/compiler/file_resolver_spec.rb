# encoding: utf-8

require 'fakefs/spec_helpers'

require_relative '../spec_helper'

require 'epuber/book'
require 'epuber/compiler'

require 'epuber/compiler/file_types/static_file'
require 'epuber/compiler/file_types/stylus_file'


module Epuber
  class Compiler

    describe FileResolver do
      include FakeFS::SpecHelpers

      before do
        FileUtils.mkdir_p(%w(source dest))
        @sut = FileResolver.new('/source', '/dest')
      end

      it 'is empty after initialization' do
        expect(@sut.files.count).to eq 0
        expect(@sut.manifest_files.count).to eq 0
      end

      it 'supports adding files from request' do
        FileUtils.touch('/source/file.txt')

        ret_file = @sut.add_file_from_request(Book::FileRequest.new('file.txt'))
        expect(ret_file).to_not be_nil

        expect(@sut.files.count).to eq 1
        expect(@sut.manifest_files.count).to eq 1
        expect(@sut.spine_files.count).to eq 0

        file = @sut.files.first
        expect(file).to_not be_nil
        expect(file.path_type).to eq :manifest
        expect(file.source_path).to eq 'file.txt'
        expect(file.destination_path).to eq 'file.txt'
        expect(file.final_destination_path).to eq '/dest/OEBPS/file.txt'
        expect(file).to be_a FileTypes::StaticFile
      end

      it 'handles multiple addition of the same file'

      it 'supports adding files with generated content'

      it 'supports adding multiple files' do
        FileUtils.touch(%w(/source/file1.xhtml /source/file2.xhtml /source/file3.xhtml /source/file4.xhtml))

        @sut.add_file_from_request(Book::FileRequest.new('*.xhtml', false))

        expect(@sut.files.map(&:source_path)).to contain_exactly 'file1.xhtml', 'file2.xhtml', 'file3.xhtml', 'file4.xhtml'
      end

      it 'can calculate path depend on path type' do
        expect(FileResolver.path_for('/root', :manifest)).to eq '/root/OEBPS'
        expect(FileResolver.path_for('/root', :spine)).to eq '/root/OEBPS'
        expect(FileResolver.path_for('/root', :package)).to eq '/root'
      end

      it 'supports searching files in source folder' do
        FileUtils.touch('/source/1.xhtml')

        expect(@sut.source_finder.find_file('1.xhtml')).to eq '1.xhtml'
      end

      it 'support searching files in destination folder'

      it 'can return file instance from source path'

      it 'can return file instance from destination path'

      it 'can find unnecessary files in destination path' do
        FileUtils.mkdir_p(%w(/dest/valid /dest/not_valid))
        FileUtils.touch(%w(/dest/valid/1.xhtml /dest/valid/2.xhtml /dest/not_valid/1.xhtml))

        FileUtils.mkdir_p(%w(/source/valid /source/not_valid))
        FileUtils.touch(%w(/source/valid/1.xhtml /source/valid/2.xhtml))

        req = Book::FileRequest.new('valid/*.xhtml', false)
        @sut.add_file_from_request(req)

        unneeded = @sut.unneeded_files_in_destination
        expect(unneeded).to contain_exactly 'not_valid/1.xhtml'
      end

      it 'can find file instance from file request' do
        FileUtils.touch('/source/some_file.xhtml')

        req = Book::FileRequest.new('/source/some_file.xhtml')
        file = @sut.add_file_from_request(req)

        same_req = Book::FileRequest.new('/source/some_file.xhtml')
        founded_file = @sut.file_from_request(same_req)

        expect(founded_file).to be file
      end

      it 'can find file instances from multi file request' do
        FileUtils.touch(%w(/source/some_file.xhtml /source/some_file2.xhtml))

        req = Book::FileRequest.new('*.xhtml', false)
        files = @sut.add_file_from_request(req)

        same_req = Book::FileRequest.new('*.xhtml', false)
        founded_files = @sut.file_from_request(same_req)

        expect(founded_files).to eq files
      end

      context '.file_class_for' do
        it 'selects correct file type from file extension' do
          expect(FileResolver.file_class_for('.styl')).to be FileTypes::StylusFile
          expect(FileResolver.file_class_for('.css')).to be FileTypes::StaticFile

          expect(FileResolver.file_class_for('.js')).to be FileTypes::StaticFile

          expect(FileResolver.file_class_for('.bade')).to be FileTypes::BadeFile
          expect(FileResolver.file_class_for('.xhtml')).to be FileTypes::XHTMLFile
          expect(FileResolver.file_class_for('.html')).to be FileTypes::XHTMLFile

          expect(FileResolver.file_class_for('.png')).to be FileTypes::StaticFile
          expect(FileResolver.file_class_for('.jpeg')).to be FileTypes::StaticFile
          expect(FileResolver.file_class_for('.jpg')).to be FileTypes::StaticFile

          expect(FileResolver.file_class_for('.otf')).to be FileTypes::StaticFile
          expect(FileResolver.file_class_for('.ttf')).to be FileTypes::StaticFile
        end
      end
    end


  end
end
