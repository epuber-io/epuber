# encoding: utf-8

require_relative '../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_types/generated_file'



module Epuber
  class Compiler
    module FileTypes



      describe GeneratedFile do
        include FakeFS::SpecHelpers

        it 'writes content into file' do
          expect(File.exist?('b.txt')).to be_falsey

          file = GeneratedFile.new('b.txt')
          file.content = 'some content'
          file.process

          expect(File.exist?('b.txt')).to be_truthy
          expect(File.read('b.txt')).to eq 'some content'
        end

      end



    end
  end
end
