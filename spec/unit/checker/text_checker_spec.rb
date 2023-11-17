# frozen_string_literal: true

require_relative '../../spec_helper'

require 'epuber/checker/text_checker'


module Epuber
  class Checker
    class TextChecker
      describe MatchProblem do
        context '#to_s' do
          it 'can format simple problem' do
            text = 'some text containing some problem'
            text =~ /text/
            match = Regexp.last_match

            problem = MatchProblem.new(match, 'Some message', '/path/to/file.txt')
            sut     = problem.to_s.split("\n")

            expect(sut.shift).to eq '/path/to/file.txt:1 column: 6 --- Some message'
            expect(sut.shift).to eq "  some #{'text'.ansi.red} containing some problem"
            expect(sut.shift).to eq    '       ^  ^'
            expect(sut).to be_empty
          end

          it 'can format one char problem' do
            text = 'some text containing some problem'
            text =~ /t/
            match = Regexp.last_match

            problem = MatchProblem.new(match, 'Some message', '/path/to/file.txt')
            sut     = problem.to_s.split("\n")

            expect(sut.shift).to eq '/path/to/file.txt:1 column: 6 --- Some message'
            expect(sut.shift).to eq "  some #{'t'.ansi.red}ext containing some problem"
            expect(sut.shift).to eq    '       ^'
            expect(sut).to be_empty
          end

          it 'handle problem at the end of line' do
            text = 'some problem'
            text =~ /problem/
            match = Regexp.last_match

            problem = MatchProblem.new(match, 'Some message', '/path/to/file.txt')
            sut     = problem.to_s.split("\n")

            expect(sut.shift).to eq '/path/to/file.txt:1 column: 6 --- Some message'
            expect(sut.shift).to eq "  some #{'problem'.ansi.red}"
            expect(sut.shift).to eq    '       ^     ^'
            expect(sut).to be_empty
          end

          it 'handle problem at the beginning of line' do
            text = 'problem some'
            text =~ /problem/
            match = Regexp.last_match

            problem = MatchProblem.new(match, 'Some message', '/path/to/file.txt')
            sut     = problem.to_s.split("\n")

            expect(sut.shift).to eq '/path/to/file.txt:1 column: 1 --- Some message'
            expect(sut.shift).to eq "  #{'problem'.ansi.red} some"
            expect(sut.shift).to eq    '  ^     ^'
            expect(sut).to be_empty
          end

          it 'handle tabs properly' do
            text = "\t\tsome text containing some problem"
            text =~ /problem/
            match = Regexp.last_match

            problem = MatchProblem.new(match, 'Some message', '/path/to/file.txt')
            sut     = problem.to_s.split("\n")

            expect(sut.shift).to eq '/path/to/file.txt:1 column: 29 --- Some message'
            expect(sut.shift).to eq "          some text containing some #{'problem'.ansi.red}"
            expect(sut.shift).to eq '                                    ^     ^'
            expect(sut).to be_empty
          end

          it 'handle new lines properly' do
            text = 'text
some other text
some text containing some problem'
            text =~ /problem/
            match = Regexp.last_match

            problem = MatchProblem.new(match, 'Some message', '/path/to/file.txt')
            sut     = problem.to_s.split("\n")

            expect(sut.shift).to eq '/path/to/file.txt:3 column: 27 --- Some message'
            expect(sut.shift).to eq "  some text containing some #{'problem'.ansi.red}"
            expect(sut.shift).to eq    '                            ^     ^'
            expect(sut).to be_empty
          end

          it 'handle long text before match properly' do
            text = "#{'some long text containing some problem ' * 10}abc"
            text =~ /abc/
            match = Regexp.last_match

            problem = MatchProblem.new(match, 'Some message', '/path/to/file.txt')
            sut     = problem.to_s.split("\n")

            expect(sut.shift).to eq '/path/to/file.txt:1 column: 391 --- Some message'
            expect(sut.shift).to eq "  some long text conta... text containing some problem #{'abc'.ansi.red}"
            expect(sut.shift).to eq    '                                                       ^ ^'
            expect(sut).to be_empty
          end

          it 'handle long text before match properly' do
            text = "bla bla abcd #{'some long text containing some problem ' * 10}"
            text =~ /abcd/
            match = Regexp.last_match

            problem = MatchProblem.new(match, 'Some message', '/path/to/file.txt')
            sut     = problem.to_s.split("\n")

            expect(sut.shift).to eq '/path/to/file.txt:1 column: 9 --- Some message'
            expect(sut.shift).to eq "  bla bla #{'abcd'.ansi.red} some long text containing some problem some long ..."
            expect(sut.shift).to eq    '          ^  ^'
            expect(sut).to be_empty
          end
        end
      end
    end
  end
end
