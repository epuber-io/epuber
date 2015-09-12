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

        @sut.add_file_from_request(Book::FileRequest.new('file.txt'))

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

      it 'supports adding files with generated content'

      it 'supports adding multiple files' do
        FileUtils.touch(%w(/source/file1.xhtml /source/file2.xhtml /source/file3.xhtml /source/file4.xhtml))

        @sut.add_file_from_request(Book::FileRequest.new('*.xhtml', false))

        expect(@sut.files.count).to eq 4
        expect(@sut.files.map(&:source_path)).to contain_exactly 'file1.xhtml', 'file2.xhtml', 'file3.xhtml', 'file4.xhtml'
      end

      it 'can calculate path depend on path type' do
        expect(FileResolver.path_for('/root', :manifest)).to eq '/root/OEBPS'
        expect(FileResolver.path_for('/root', :spine)).to eq '/root/OEBPS'
        expect(FileResolver.path_for('/root', :package)).to eq '/root'
      end

      it 'supports searching files in source folder'
      it 'support searching files in destination folder'
      it 'can return file instance from source path'
      it 'can return file instance from destination path'
      it 'can find unnecessary files in destination path'

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
