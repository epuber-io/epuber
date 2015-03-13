
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

      def replace_all(regex, sub = nil, multiple_times: false, &block)
        result = if sub.nil?
                   @text.gsub!(regex, &block)
                 else
                   @text.gsub!(regex, sub, &block)
                 end

        result = replace_all(regex, sub, multiple_times: multiple_times, &block) if multiple_times && !result.nil?
        result
      end
    end
  end
end
