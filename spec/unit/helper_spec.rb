# frozen_string_literal: true

require_relative '../spec_helper'

require 'epuber/helper'

require 'epuber/book'
require 'epuber/compiler'


module Epuber
  describe Helper do
    include FakeFS::SpecHelpers

    describe '.destination_path_for_toc_item' do
      before do
        FileUtils.mkdir_p('/src')
        FileUtils.mkdir_p('/dest')

        @resolver = Compiler::FileResolver.new('/src', '/dest')


        FileUtils.mkdir_p('/src/path')
        FileUtils.touch('/src/path/a.txt')

        @simple_item = Book::TocItem.new
        @simple_item.file_request = Book::FileRequest.new('a.txt')

        @fragment_item = Book::TocItem.new
        @fragment_item.file_request = Book::FileRequest.new('a.txt')
        @fragment_item.file_fragment = 'fragment'

        @only_fragment_item = Book::TocItem.new
        @only_fragment_item.file_fragment = 'fragment'
      end

      it 'creates pretty path for simple example' do
        @resolver.add_file_from_request(@simple_item.file_request)

        path = described_class.destination_path_for_toc_item(@simple_item, @resolver, '/')
        expect(path).to eq 'dest/OEBPS/path/a.txt'

        path = described_class.destination_path_for_toc_item(@simple_item, @resolver, '/dest/OEBPS')
        expect(path).to eq 'path/a.txt'
      end

      it 'creates pretty path with fragment' do
        @resolver.add_file_from_request(@fragment_item.file_request)

        path = described_class.destination_path_for_toc_item(@fragment_item, @resolver, '/')
        expect(path).to eq 'dest/OEBPS/path/a.txt#fragment'

        path = described_class.destination_path_for_toc_item(@fragment_item, @resolver, '/dest/OEBPS')
        expect(path).to eq 'path/a.txt#fragment'
      end

      it 'creates pretty path with nested item' do
        # set parent for fragment item
        @fragment_item.instance_variable_set(:@parent, @simple_item)

        @resolver.add_file_from_request(@fragment_item.file_request)

        path = described_class.destination_path_for_toc_item(@fragment_item, @resolver, '/')
        expect(path).to eq 'dest/OEBPS/path/a.txt#fragment'

        path = described_class.destination_path_for_toc_item(@fragment_item, @resolver, '/dest/OEBPS')
        expect(path).to eq 'path/a.txt#fragment'
      end

      it 'creates pretty path with fragment only child item' do
        # set parent for fragment item
        @only_fragment_item.instance_variable_set(:@parent, @simple_item)

        @resolver.add_file_from_request(@only_fragment_item.file_request)

        path = described_class.destination_path_for_toc_item(@only_fragment_item, @resolver, '/')
        expect(path).to eq 'dest/OEBPS/path/a.txt#fragment'

        path = described_class.destination_path_for_toc_item(@only_fragment_item, @resolver, '/dest/OEBPS')
        expect(path).to eq 'path/a.txt#fragment'
      end
    end
  end
end
