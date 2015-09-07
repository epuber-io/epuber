# encoding: utf-8

require 'fakefs/spec_helpers'

require_relative '../spec_helper'

require 'epuber/book'
require 'epuber/compiler'




module Epuber
  class Compiler

    describe FileFinder do
      include FakeFS::SpecHelpers

      it 'stores info from init' do
        finder = FileFinder.new('dasdasas')
        expect(finder.source_path).to eq 'dasdasas'
      end

      it 'can find file' do
        FileUtils.touch(['a.xhtml', 'b.xhtml'])

        finder = FileFinder.new('.')
        files = finder.find_files('*.xhtml')
        expect(files.count).to eq 2
      end
    end

  end
end
