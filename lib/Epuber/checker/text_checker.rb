
require_relative '../checker'
require_relative '../ruby_extensions/match_data'


module Epuber
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

        %{#{@file_path}:#{@match.line_number} --- #{@message}
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

    # @param text [String]
    #
    def call(file_path, text)
      @file_path = file_path
      @text = text

      @block.call(self, text)

      @text = nil
      @file_path = nil
    end

    # @param regexp [Regexp]
    #
    def should_not_find(regexp, message)
      # find all matches
      matches = text.to_enum(:scan, regexp).map { Regexp.last_match }

      if matches.length > 0
        lines = text.split(/\r?\n/)

        matches.each do |match|
          # @type match [MatchData]
          puts MatchProblem.new(match, message, file_path)
        end
      end

      #raise CheckerWarning, 'founded'
    end
  end
end
