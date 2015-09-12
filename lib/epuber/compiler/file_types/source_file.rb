# encoding: utf-8


module Epuber
  class Compiler
    module FileTypes
      require_relative 'abstract_file'

      class SourceFile < AbstractFile

        # @return [String] relative source path
        #
        attr_reader :source_path

        # @return [Epuber::Book::FileRequest]
        #
        attr_accessor :file_request

        # @param [String] source_path  relative path from project root to source file
        #
        def initialize(source_path)
          @source_path = source_path
        end

        def process(opts = {})
          raise 'Abstract method, implement in subclass!'
        end
      end
    end
  end
end