# frozen_string_literal: true

require_relative '../../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_types/abstract_file'


module Epuber
  class Compiler
    module FileTypes
      describe AbstractFile do
        include FakeFS::SpecHelpers

        context 'write_to_file?' do
          it 'do not need to write when the file is same' do
            File.write('a.txt', 'some content, so we can compare it')

            expect(AbstractFile.write_to_file?('some content, so we can compare it', 'a.txt')).to be_falsey
          end

          it 'needs to write when the file is different' do
            File.write('a.txt', 'some content, so we can compare it')

            expect(AbstractFile.write_to_file?('some different content', 'a.txt')).to be_truthy
          end
        end
      end
    end
  end
end
