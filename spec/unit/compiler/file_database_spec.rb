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

        sut.cleanup(%w(/file))

        expect(sut.all_files.count).to eq 1
        expect(sut.all_files['/file']).to_not be_nil
        expect(sut.all_files['/file_old']).to be_nil
      end

      context 'dependencies' do
        it 'can have dependency' do
          File.write('/file_dep', 'abc')
          File.write('/file', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency('/file_dep', to: '/file')

          expect(sut.all_files.count).to eq 2
          expect(sut.all_files['/file']).to_not be_nil
          expect(sut.all_files['/file_dep']).to_not be_nil

          expect(sut.up_to_date?('/file')).to be_truthy
        end

        it 'resolve dependency' do
          File.write('/file', 'abc')
          File.write('/file_dep', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency('/file_dep', to: '/file')

          expect(sut.up_to_date?('/file')).to be_truthy

          # make the dependency file newer
          File.write('/file_dep', 'abc def')

          expect(sut.up_to_date?('/file')).to be_falsey
        end

        it 'handle not-existing files correctly' do
          File.write('/file', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency('/file_dep', to: '/file')

          expect(sut.up_to_date?('/file')).to be_truthy
        end

        it 'resolve transitive dependency' do
          File.write('/file', 'abc')
          File.write('/file_dep', 'abc')
          File.write('/file_dep2', 'abc')
          File.write('/file_dep3', 'abc')
          File.write('/file_dep4', 'abc')
          File.write('/file_dep5', 'abc')
          File.write('/file_dep6', 'abc')
          File.write('/file_dep7', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency('/file_dep', to: '/file')
          sut.add_dependency('/file_dep2', to: '/file_dep')
          sut.add_dependency('/file_dep3', to: '/file_dep2')
          sut.add_dependency('/file_dep4', to: '/file_dep3')
          sut.add_dependency('/file_dep5', to: '/file_dep4')
          sut.add_dependency('/file_dep6', to: '/file_dep5')
          sut.add_dependency('/file_dep7', to: '/file_dep6')

          # make the dependency file newer
          File.write('/file_dep7', 'abc def')

          expect(sut.up_to_date?('/file')).to be_falsey
        end

        it 'cleans up transitive dependency' do
          File.write('/file', 'abc')
          File.write('/file_dep', 'abc')
          File.write('/file_dep2', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency('/file_dep', to: '/file')
          sut.add_dependency('/file_dep2', to: '/file_dep')

          sut.cleanup(%w(/file /file_dep))

          expect(sut.all_files.count).to eq 2
          expect(sut.all_files['/file']).to_not be_nil
          expect(sut.all_files['/file_dep']).to_not be_nil
          expect(sut.all_files['/file_dep2']).to be_nil

          expect(sut.all_files['/file_dep'].dependency_paths).to be_empty
        end
      end
    end

  end
end
