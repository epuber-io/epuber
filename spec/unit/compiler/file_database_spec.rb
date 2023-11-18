# frozen_string_literal: true

require_relative '../../spec_helper'

require 'epuber/compiler'


module Epuber
  class Compiler
    describe FileDatabase do
      include FakeFS::SpecHelpers

      let(:sut) { described_class.new('/db') }

      it 'can load from file' do
        expect(sut.store_file_path).to eq '/db'
        expect(sut.all_files).to eq({})
      end

      it 'can save to file and load back' do
        File.write('/file', 'abc')

        sut.update_metadata('/file')
        sut.save_to_file

        inst2 = described_class.new('/db')
        expect(inst2.all_files).to eq sut.all_files
        expect(inst2.all_files.count).to eq 1
        expect(inst2.all_files['/file']).to be_a(FileStat)
      end

      it 'can track whether some file has changed the content size' do
        File.write('/file', 'abc')
        sut.update_metadata('/file')

        File.write('/file', 'abc def')

        expect(sut).to be_changed('/file')
      end

      it 'can track whether some file has changed the mtime or ctime' do
        File.write('/file', 'abc')
        sut.update_metadata('/file')

        File.write('/file', 'abc')

        expect(sut).to be_changed('/file')
      end

      it 'can track whether some file has not changed' do
        File.write('/file', 'abc')
        sut.update_metadata('/file')

        expect(sut).not_to be_changed('/file')
      end

      it 'can cleanup old files' do
        File.write('/file', 'abc')
        File.write('/file_old', 'abc')

        sut.update_metadata('/file')
        sut.update_metadata('/file_old')

        expect(sut.all_files.count).to eq 2
        expect(sut.all_files['/file']).not_to be_nil
        expect(sut.all_files['/file_old']).not_to be_nil

        sut.cleanup(%w[/file])

        expect(sut.all_files.count).to eq 1
        expect(sut.all_files['/file']).not_to be_nil
        expect(sut.all_files['/file_old']).to be_nil
      end

      describe 'dependencies' do
        it 'can have dependecy' do
          File.write('/file_dep', 'abc')
          File.write('/file', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency('/file_dep', to: '/file')

          expect(sut.all_files.count).to eq 2
          expect(sut.all_files['/file']).not_to be_nil
          expect(sut.all_files['/file_dep']).not_to be_nil
        end

        it 'dependency is implicitly in unknown state' do
          File.write('/file_dep', 'abc')
          File.write('/file', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency('/file_dep', to: '/file')

          expect(sut).not_to be_up_to_date('/file')
        end

        it 'dependency is implicitly in unknown state, must call update_metadata' do
          File.write('/file_dep', 'abc')
          File.write('/file', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency('/file_dep', to: '/file')
          sut.update_metadata('/file_dep') # added

          expect(sut).to be_up_to_date('/file')
        end

        it 'can add dependencies as array' do
          File.write('/file_dep1', 'abc')
          File.write('/file_dep2', 'abc')
          File.write('/file', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency(%w[/file_dep1 /file_dep2], to: '/file')

          expect(sut.all_files.count).to eq 3
          expect(sut.all_files['/file']).not_to be_nil
          expect(sut.all_files['/file_dep1']).not_to be_nil
          expect(sut.all_files['/file_dep2']).not_to be_nil

          expect(sut).not_to be_up_to_date('/file')
        end

        it 'can add dependencies as array, but must call update_metadata on each' do
          File.write('/file_dep1', 'abc')
          File.write('/file_dep2', 'abc')
          File.write('/file', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency(%w[/file_dep1 /file_dep2], to: '/file')
          sut.update_metadata('/file_dep1')
          sut.update_metadata('/file_dep2')

          expect(sut).to be_up_to_date('/file')
        end

        it 'can save to file and load back with dependencies' do
          File.write('/file', 'abc')
          File.write('/file_dep', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency('/file_dep', to: '/file')
          sut.save_to_file

          inst2 = described_class.new('/db')
          expect(inst2.all_files).to eq sut.all_files
          expect(inst2.all_files.count).to eq 2
          expect(inst2.all_files['/file']).to be_a(FileStat)
          expect(inst2.all_files['/file'].dependency_paths).to contain_exactly('/file_dep')
        end

        it 'resolve dependency' do
          File.write('/file', 'abc')
          File.write('/file_dep', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency('/file_dep', to: '/file')

          # dependency is unknown file, so it must be falsey
          expect(sut).not_to be_up_to_date('/file')

          sut.update_metadata('/file_dep')

          # now the dependency is updated in database
          expect(sut).to be_up_to_date('/file')

          # make the dependency file newer
          File.write('/file_dep', 'abc def')

          expect(sut).not_to be_up_to_date('/file')
        end

        it 'handle not-existing files correctly' do
          File.write('/file', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency('/file_dep', to: '/file')

          expect(sut).to be_up_to_date('/file')
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
          sut.update_metadata('/file_dep')
          sut.add_dependency('/file_dep2', to: '/file_dep')
          sut.update_metadata('/file_dep2')
          sut.add_dependency('/file_dep3', to: '/file_dep2')
          sut.update_metadata('/file_dep3')
          sut.add_dependency('/file_dep4', to: '/file_dep3')
          sut.update_metadata('/file_dep4')
          sut.add_dependency('/file_dep5', to: '/file_dep4')
          sut.update_metadata('/file_dep5')
          sut.add_dependency('/file_dep6', to: '/file_dep5')
          sut.update_metadata('/file_dep6')
          sut.add_dependency('/file_dep7', to: '/file_dep6')
          sut.update_metadata('/file_dep7')

          # make the dependency file newer
          File.write('/file_dep7', 'abc def')

          expect(sut).not_to be_up_to_date('/file')
        end

        it 'cleans up transitive dependency' do
          File.write('/file', 'abc')
          File.write('/file_dep', 'abc')
          File.write('/file_dep2', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency('/file_dep', to: '/file')
          sut.add_dependency('/file_dep2', to: '/file_dep')

          sut.cleanup(%w[/file /file_dep])

          expect(sut.all_files.count).to eq 2
          expect(sut.all_files['/file']).not_to be_nil
          expect(sut.all_files['/file_dep']).not_to be_nil
          expect(sut.all_files['/file_dep2']).to be_nil

          expect(sut.all_files['/file_dep'].dependency_paths).to be_empty
        end

        it 'updates all metadata' do
          File.write('/file', 'abc')
          File.write('/file_dep', 'abc')
          File.write('/file_dep2', 'abc')

          sut.update_metadata('/file')
          sut.add_dependency('/file_dep', to: '/file')
          sut.update_metadata('/file_dep')
          sut.add_dependency('/file_dep2', to: '/file_dep')
          sut.update_metadata('/file_dep2')

          expect(sut).to be_up_to_date('/file')

          FileUtils.touch('/file_dep2')

          expect(sut).not_to be_up_to_date('/file')

          sut.update_all_metadata

          expect(sut).to be_up_to_date('/file')
        end
      end
    end
  end
end
