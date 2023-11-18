# frozen_string_literal: true

require_relative '../../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_types/generated_file'



module Epuber
  class Compiler
    module FileTypes
      describe GeneratedFile do
        include FakeFS::SpecHelpers

        it 'writes content into file' do
          expect(File).not_to exist('b.txt')

          file = described_class.new
          file.destination_path = 'b.txt'
          file.final_destination_path = '/b.txt'
          file.content = 'some content'
          file.process(nil)

          expect(File).to exist('b.txt')
          expect(File.read('b.txt')).to eq 'some content'
        end
      end
    end
  end
end
