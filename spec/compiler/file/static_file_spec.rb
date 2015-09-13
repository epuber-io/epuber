# encoding: utf-8

require_relative '../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_types/static_file'


module Epuber
  class Compiler
    module FileTypes



      describe StaticFile do
        include FakeFS::SpecHelpers

        it "copy file's content to destination" do
          File.write('a.txt', 'some content, so we can compare it')

          expect(File.exist?('b.txt')).to be_falsey

          file = StaticFile.new('a.txt')
          file.destination_path = 'b.txt'

          file.abs_source_path = '/a.txt'
          file.final_destination_path = '/b.txt'

          file.process

          expect(File.exist?('b.txt')).to be_truthy
          expect(File.read('b.txt')).to eq 'some content, so we can compare it'
        end

      end



    end
  end
end
