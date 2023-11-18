# frozen_string_literal: true

require_relative '../../spec_helper'

require 'epuber/compiler/problem'


module Epuber
  class Compiler
    describe Problem do
      describe '.text_at' do
        it 'can split single line text at start' do
          input = <<~TEXT
            some text single line
          TEXT
          location = Problem::Location.new(1, 1, 4)

          expect(described_class.text_at(input, location)).to eq ['', 'some', ' text single line']
        end

        it 'can split single line text in middle' do
          input = <<~TEXT
            some text single line
          TEXT
          location = Problem::Location.new(1, 6, 4)

          expect(described_class.text_at(input, location)).to eq ['some ', 'text', ' single line']
        end

        it 'can split single line text at end' do
          input = <<~TEXT
            some text single line
          TEXT
          location = Problem::Location.new(1, 18, 4)

          expect(described_class.text_at(input, location)).to eq ['some text single ', 'line', '']
        end

        it 'can split single line text with no length' do
          input = <<~TEXT
            some text single line
          TEXT
          location = Problem::Location.new(1, 6)

          expect(described_class.text_at(input, location)).to eq ['some ', 't', 'ext single line']
        end

        it 'can split multi line text' do
          input = <<~TEXT
            some text single line
            some text single line 2
            some text single line 3
          TEXT
          location = Problem::Location.new(2, 6, 4)

          expect(described_class.text_at(input,
                                         location)).to eq ["some text single line\nsome ", 'text',
                                                           " single line 2\nsome text single line 3"]
        end
      end

      describe '.formatted_match_line' do
        it 'takes only single line' do
          input = <<~TEXT
            some text single line
            some text single line 2
            some text single line 3
          TEXT

          location = Problem::Location.new(2, 6, 4)

          expect(described_class.formatted_match_line(input, location)).to eq ['some ', 'text', ' single line 2']
        end
      end
    end
  end
end
