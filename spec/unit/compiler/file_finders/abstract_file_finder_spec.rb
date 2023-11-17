# frozen_string_literal: true

require_relative '../../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'




module Epuber
  class Compiler
    describe FileFinders do
      include FakeFS::SpecHelpers

      context '::MultipleFilesFoundError' do
        it 'can handle to_s for empty groups' do
          expect do
            FileFinders::MultipleFilesFoundError.new('some_pattern*', [], '/some_context_path/aaa', ['abc', 'def']).to_s
          end.to_not raise_error
        end

        it 'can handle to_s for nil groups' do
          expect do
            FileFinders::MultipleFilesFoundError.new('some_pattern*', nil, '/some_context_path/aaa',
                                                     ['abc', 'def']).to_s
          end.to_not raise_error
        end

        it 'can handle to_s for one group' do
          expect do
            FileFinders::MultipleFilesFoundError.new('some_pattern*', :text, '/some_context_path/aaa',
                                                     ['abc', 'def']).to_s
          end.to_not raise_error
        end
      end
    end
  end
end
