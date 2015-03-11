
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


      # @param file_path [String]
      # @param text [String]
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

      def replace_all(regex, sub = nil, &block)
        if sub.nil?
          @text = @text.gsub(regex, &block)
        else
          @text = @text.gsub(regex, sub, &block)
        end
      end
    end
  end
end
