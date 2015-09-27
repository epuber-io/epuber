# encoding: utf-8

require 'active_support/core_ext/string/access'

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
          @match = match
          @message = message
          @file_path = file_path
        end

        # Formats caret symbol with space indent
        #
        # @param [Fixnum] indent
        #
        # @return [String]
        #
        def caret_symbol(indent)
          ' ' * indent + '^'
        end

        # Formats caret symbols for indent and length
        #
        # @param [Fixnum] length
        # @param [Fixnum] indent
        #
        # @return [String]
        #
        def caret_symbols(indent, length)
          start_sign = caret_symbol(indent)
          end_sign = if length > 1
                       caret_symbol(length-2)
                     else
                       ''
                     end

          "#{start_sign}#{end_sign}"
        end

        def remove_tabs(text)
          text.gsub("\t", ' ' * 4)
        end

        def to_s
          match_line = @match.matched_string
          post_line = @match.post_match_lines.first
          pre_line = @match.pre_match_lines.last

          pre = match_pre_line = pre_line
          if remove_tabs(match_pre_line).length > 100
            pre = "#{match_pre_line.first(20)} ... #{match_pre_line.last(30)}"
          end

          pre = remove_tabs(pre)

          post = "#{post_line.first(20)} ..."

          pointers = caret_symbols(pre.length, match_line.length)

          %{#{@file_path}:#{@match.line_number} column: #{match_pre_line.length} --- #{@message}
  #{pre + match_line.ansi.red + post}
  #{pointers}}
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

      # @param regexp [Regexp]
      # @param [String] message  message to display, when the regexp found something
      #
      def should_not_contain(regexp, message)
        # find all matches
        # taken from http://stackoverflow.com/questions/6804557/how-do-i-get-the-match-data-for-all-occurrences-of-a-ruby-regular-expression-in
        matches = text.to_enum(:scan, regexp).map { Regexp.last_match }
        matches.each do |match|
          # @type match [MatchData]
          UI.print_processing_problem MatchProblem.new(match, message, Config.instance.pretty_path_from_project(file_path))
        end
      end
    end
  end
end
