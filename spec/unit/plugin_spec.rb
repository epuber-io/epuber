# frozen_string_literal: true

require_relative '../spec_helper'

require 'epuber/plugin'


module Epuber
  describe Plugin do
    include FakeFS::SpecHelpers

    describe '.init' do
      it 'from file' do
        FileUtils.touch('plugin.rb')

        plugin = described_class.new('plugin.rb')
        file = plugin.files.first
        expect(file.source_path).to eq 'plugin.rb'
        expect(file.abs_source_path).to eq '/plugin.rb'
      end

      it 'from file in deep structure' do
        FileUtils.mkdir_p('/some/nested/dir/structure')

        Dir.chdir('/some/nested/dir/structure') do
          FileUtils.touch('plugin.rb')

          plugin = described_class.new('plugin.rb')
          file = plugin.files.first

          expect(file.source_path).to eq 'plugin.rb'
          expect(file.abs_source_path).to eq '/some/nested/dir/structure/plugin.rb'
        end
      end

      it 'from file in deep structure 2' do
        FileUtils.mkdir_p('/some/nested/dir/structure')
        FileUtils.touch('/some/nested/dir/structure/plugin.rb')

        plugin = described_class.new('some/nested/dir/structure/plugin.rb')
        file = plugin.files.first

        expect(file.source_path).to eq 'some/nested/dir/structure/plugin.rb'
        expect(file.abs_source_path).to eq '/some/nested/dir/structure/plugin.rb'
      end

      it 'from empty folder' do
        FileUtils.mkdir_p('plugin')

        plugin = described_class.new('plugin')
        expect(plugin.files).to be_empty
      end

      it 'from folder with .rb file' do
        FileUtils.mkdir_p('plugin')
        FileUtils.touch('plugin/plugin.rb')

        plugin = described_class.new('plugin')
        file = plugin.files.first
        expect(file.source_path).to eq 'plugin/plugin.rb'
        expect(file.abs_source_path).to eq '/plugin/plugin.rb'
      end

      it "raise exception when the file doesn't exist" do
        expect do
          described_class.new('plugin.rb')
        end.to raise_exception LoadError
      end

      it "raise exception when the folder doesn't exist" do
        expect do
          described_class.new('plugin/')
        end.to raise_exception LoadError
      end
    end
  end
end
