# encoding: utf-8


module Epuber
  class Compiler
    class Problem
      class Location
        attr_reader :line
        attr_reader :column
        attr_reader :length

        def initialize(line, column, length = nil)
          @line = line
          @column = column
          @length = length || 1
        end
      end

      attr_reader :level
      attr_reader :message
      attr_reader :source
      attr_reader :location
      attr_reader :file_path

      def initialize(level, message, source, location: nil, line: nil, column: nil, length: nil, file_path: nil)
        @level = level
        @message = message
        @source = source
        @location = location
        if @location.nil? && line && column
          @location = Location.new(line, column, length)
        end

        @file_path = file_path
      end

      # Formats caret symbol with space indent
      #
      # @param [Fixnum] indent
      #
      # @return [String]
      #
      def self.caret_symbol(indent)
        ' ' * indent + '^'
      end

      # Formats caret symbols for indent and length
      #
      # @param [Fixnum] length
      # @param [Fixnum] indent
      #
      # @return [String]
      #
      def self.caret_symbols(indent, length)
        start_sign = caret_symbol(indent)
        end_sign = if length > 1
                     caret_symbol(length-2)
                   else
                     ''
                   end

        "#{start_sign}#{end_sign}"
      end

      def self.remove_tabs(text)
        text.gsub("\t", ' ' * 4)
      end

      # @param [Location] location
      #
      def self.text_at(text, location)
        line_index = location.line - 1
        column_index = location.column - 1

        lines = text.split("\n")

        line = lines[line_index] || ''
        matched_text = line[column_index ... column_index + location.length] || ''

        pre = (lines[0 ... line_index] + [line[0 ... column_index]]).join("\n")
        post = ([line[column_index + location.length .. line.length]] + (lines[location.line .. lines.count] || [])).join("\n")

        [pre, matched_text, post]
      end

      def self.formatted_match_line(text, location)
        pre, matched, post = text_at(text, location)

        pre_line = pre.split("\n").last || ''
        post_line = post.split("\n").first || ''

        pre = match_pre_line = pre_line
        if remove_tabs(match_pre_line).length > 100
          pre = "#{match_pre_line.first(20)}...#{match_pre_line.last(30)}"
        end

        pre = remove_tabs(pre)

        post = if post_line.length > 50
                 "#{post_line.first(50)}..."
               else
                 post_line
               end

        [pre, matched, post]
      end

      def to_s
        pre, match_text, post = self.class.formatted_match_line(@source, @location)

        pointers = self.class.caret_symbols(pre.length, @location.length)
        colored_match_text = match_text.empty? ? match_text : match_text.ansi.red
        column = @location.column
        line = [@location.line, 1].max

        [
          "#{@file_path}:#{line} column: #{column} --- #{@message}",
          '  ' + pre + colored_match_text + post,
          '  ' + pointers,
        ].join("\n")
      end
    end
  end
end
