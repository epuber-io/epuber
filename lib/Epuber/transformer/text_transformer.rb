# encoding: utf-8

require_relative '../transformer'


module Epuber
  class Transformer
    class TextTransformer < Transformer

      # @return [String]
      #
      attr_accessor :text

      # @return [String]
      #
      attr_accessor :file_path


      # @param [String] file_path  path to transforming file
      # @param [String] text  text file content
      #
      # @return [String] new transformed text
      #
      def call(file_path, text)
        @file_path = file_path
        @text = text.dup

        @block.call(self, @text)

        new_text = @text

        @text = nil
        @file_path = nil

        new_text
      end

      # Shortcut for performing substitutions in text
      #
      # @param [Regexp, String] pattern
      # @param [String, nil] replacement
      # @param [Bool] multiple_times  run the replacement multiple times, while there is something to replace
      # @param [Proc] block  optional block for creating replacements, see String#gsub!
      #
      # @return [String, nil] see String#gsub!
      #
      def replace_all(pattern, replacement = nil, multiple_times: false, &block)
        result = if replacement.nil?
                   @text.gsub!(pattern, &block)
                 else
                   @text.gsub!(pattern, replacement, &block)
                 end

        result = replace_all(pattern, replacement, multiple_times: multiple_times, &block) if multiple_times && !result.nil?
        result
      end
    end
  end
end
