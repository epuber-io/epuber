# frozen_string_literal: true

require_relative '../../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'




module Epuber
  class Compiler
    describe FileFinders do
      include FakeFS::SpecHelpers

      describe FileFinders::MultipleFilesFoundError do
        it 'can handle to_s for empty groups' do
          expect do
            described_class.new('some_pattern*', [], '/some_context_path/aaa', %w[abc def]).to_s
          end.not_to raise_error
        end

        it 'can handle to_s for nil groups' do
          expect do
            described_class.new('some_pattern*', nil, '/some_context_path/aaa',
                                %w[abc def]).to_s
          end.not_to raise_error
        end

        it 'can handle to_s for one group' do
          expect do
            described_class.new('some_pattern*', :text, '/some_context_path/aaa',
                                %w[abc def]).to_s
          end.not_to raise_error
        end
      end
    end
  end
end
