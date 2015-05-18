# encoding: utf-8

require_relative '../ruby_extensions/match_data'
require_relative '../checker'


module Epuber
  class Checker
    class TextChecker < Checker
      class MatchProblem
        # @param message [String]
        # @param file_path [String]
        # @param match [MatchData]
        #
        def initialize(match, message, file_path)
          @message = message
          @file_path = file_path
          @match = match
        end

        def to_s
          match_pre_line = @match.pre_match_lines.last
          match_length = @match.matched_string.length
          start_sign = "#{' ' * match_pre_line.length}^"
          end_sign = if match_length > 1
                       "#{' ' * (match_length-2)}^"
                     else
                       ''
                     end

          %{#{@file_path}:#{@match.line_number} column: #{match_pre_line.length} --- #{@message}
  #{@match.matched_line}
  #{start_sign}#{end_sign}}
        end
      end

      # @return [String]
      #
      attr_accessor :text

      # @return [String]
      #
      attr_accessor :file_path



      # @param file_path [String]
      # @param text [String]
      #
      # @return nil
      #
      def call(file_path, text)
        @file_path = file_path
        @text = text

        @block.call(self, text)

        @text = nil
        @file_path = nil
      end

      # @param regexp [Regexp]
      # @param [String] message  message to display, when the regexp found something
      #
      def should_not_contain(regexp, message)
        # find all matches
        # taken from http://stackoverflow.com/questions/6804557/how-do-i-get-the-match-data-for-all-occurrences-of-a-ruby-regular-expression-in
        matches = text.to_enum(:scan, regexp).map { Regexp.last_match }
        matches.each do |match|
          # @type match [MatchData]
          puts MatchProblem.new(match, message, file_path)
        end
      end
    end
  end
end
