# frozen_string_literal: true

require_relative '../checker'

module Epuber
  class Checker
    class BookspecChecker < Checker
      # @return [Epuber::Book]
      #
      attr_reader :book

      # @param [Epuber::Book] book
      # @param [CompilationContext] compilation_context
      #
      # @return nil
      #
      def call(book, compilation_context)
        @book = book

        @block.call(self, book, compilation_context)

        @book = nil
      end
    end
  end
end
