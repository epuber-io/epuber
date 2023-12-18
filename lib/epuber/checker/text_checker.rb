# frozen_string_literal: true

require 'active_support/core_ext/string/access'

require_relative '../ruby_extensions/match_data'
require_relative '../checker'
require_relative '../compiler/problem'

module Epuber
  class Checker
    class TextChecker < Checker
      class MatchProblem < Compiler::Problem
        # @param [String] message
        # @param [String] file_path
        # @param [MatchData] match
        #
        def initialize(match, message, file_path)
          whole_text = match.pre_match + match.matched_string + match.post_match

          line = match.pre_match_lines.count
          column = (match.pre_match_lines.last || '').length + 1
          length = match.matched_string.length
          location = Epuber::Compiler::Problem::Location.new(line, column, length)

          super(:warn, message, whole_text, location: location, file_path: file_path)
        end
      end

      # @return [String]
      #
      attr_accessor :text

      # @return [String]
      #
      attr_accessor :file_path



      # @param [String] file_path
      # @param [String] text
      # @param [CompilationContext] compilation_context
      #
      # @return nil
      #
      def call(file_path, text, compilation_context)
        @file_path = file_path
        @text = text

        @block.call(self, text, compilation_context)

        @text = nil
        @file_path = nil
      end

      # @param [Regexp] regexp
      # @param [String] message  message to display, when the regexp found something
      #
      def should_not_contain(regexp, message)
        # find all matches
        # taken from http://stackoverflow.com/questions/6804557/how-do-i-get-the-match-data-for-all-occurrences-of-a-ruby-regular-expression-in
        matches = text.to_enum(:scan, regexp).map { Regexp.last_match }
        matches.each do |match|
          # @type match [MatchData]
          UI.print_processing_problem MatchProblem.new(match, message,
                                                       Config.instance.pretty_path_from_project(file_path))
        end
      end
    end
  end
end
