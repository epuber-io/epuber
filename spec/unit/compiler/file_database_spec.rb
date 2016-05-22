# encoding: utf-8

require_relative '../../spec_helper'

require 'epuber/compiler'


module Epuber
  class Compiler

    describe FileDatabase do
      include FakeFS::SpecHelpers

      let(:sut) { FileDatabase.new('/db') }

      it 'can load from file' do
        expect(sut.store_file_path).to eq '/db'
        expect(sut.all_files).to eq Hash.new
      end

      it 'can save to file and load back' do
        File.write('/file', 'abc')

        sut.update_metadata('/file')
        sut.save_to_file

        inst2 = FileDatabase.new('/db')
        expect(sut.all_files).to eq inst2.all_files
        expect(sut.all_files.count).to eq 1
        expect(sut.all_files['/file']).to be_a(FileStat)
      end

      it 'can track whether some file has changed the content size' do
        File.write('/file', 'abc')
        sut.update_metadata('/file')

        File.write('/file', 'abc def')

        expect(sut.changed?('/file')).to be_truthy
      end

      it 'can track whether some file has changed the mtime or ctime' do
        File.write('/file', 'abc')
        sut.update_metadata('/file')

        File.write('/file', 'abc')

        expect(sut.changed?('/file')).to be_truthy
      end

      it 'can track whether some file has not changed' do
        File.write('/file', 'abc')
        sut.update_metadata('/file')

        expect(sut.changed?('/file')).to be_falsey
      end

      it 'can cleanup old files' do
        File.write('/file', 'abc')
        File.write('/file_old', 'abc')

        sut.update_metadata('/file')
        sut.update_metadata('/file_old')

        expect(sut.all_files.count).to eq 2
        expect(sut.all_files['/file']).to_not be_nil
        expect(sut.all_files['/file_old']).to_not be_nil

        sut.cleanup(['/file'])

        expect(sut.all_files.count).to eq 1
        expect(sut.all_files['/file']).to_not be_nil
        expect(sut.all_files['/file_old']).to be_nil
      end
    end

  end
end
