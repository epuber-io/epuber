# frozen_string_literal: true

require_relative '../transformer'

module Epuber
  class Transformer
    class BookTransformer < Transformer
      # @return [Book]
      #
      attr_accessor :book

      # @return [CompilationContext]
      #
      attr_accessor :compilation_context

      # @param [Epuber::Book] book
      # @param [Epuber::Compiler::CompilationContext] compilation_context
      #
      def call(book, compilation_context)
        @book = book
        @compilation_context = compilation_context

        @block.call(self, @book, @compilation_context)

        @book = nil
        @compilation_context = nil
      end

      # Find file in source or destination paths
      #
      # @param [String] pattern
      # @param [Thread::Backtrace::Location] location
      #
      # @return [Epuber::Compiler::FileTypes::AbstractFile, nil]
      #
      def find_file(pattern, location: caller_locations.first)
        return pattern if pattern.is_a?(Compiler::FileTypes::AbstractFile)

        UI.error!("Pattern for finding file can't be nil", location: location) if pattern.nil?

        begin
          path = @compilation_context.file_resolver.source_finder.find_file(pattern)
          @compilation_context.file_resolver.file_with_source_path(path)
        rescue Compiler::FileFinders::FileNotFoundError
          begin
            path = @compilation_context.file_resolver.dest_finder.find_file(pattern)
            @compilation_context.file_resolver.file_with_destination_path(path)
          rescue Compiler::FileFinders::FileNotFoundError
            nil
          end
        end
      end

      # Find files destination paths
      #
      # @param [String] pattern
      # @param [Thread::Backtrace::Location] location
      #
      # @return [Array<Epuber::Compiler::FileTypes::AbstractFile>]
      #
      def find_destination_files(pattern, location: caller_locations.first)
        UI.error!("Pattern for finding file can't be nil", location: location) if pattern.nil?

        paths = @compilation_context.file_resolver.dest_finder.find_files(pattern)
        paths.map { |path| @compilation_context.file_resolver.file_with_destination_path(path) }
      end

      # Find file and raise exception if not found
      #
      # @param [String] pattern
      # @param [Thread::Backtrace::Location] location
      #
      # @return [Epuber::Compiler::FileTypes::AbstractFile]
      #
      def get_file(pattern, location: caller_locations.first)
        file = find_file(pattern, location: location)
        UI.error!("File with pattern #{pattern} not found", location: location) unless file

        file
      end

      # Read file from destination path (raises exception if not found)
      #
      # @param [String] pattern
      # @param [Thread::Backtrace::Location] location
      #
      # @return [String]
      #
      def read_destination_file(pattern, location: caller_locations.first)
        file = get_file(pattern, location: location)
        File.read(file.final_destination_path)
      end

      # Write file to destination path (raises exception if not found)
      #
      # @param [String] pattern
      # @param [String] content
      # @param [Thread::Backtrace::Location] location
      #
      # @return [void]
      #
      def write_destination_file(pattern, content, location: caller_locations.first)
        file = get_file(pattern, location: location)
        Compiler::FileTypes::AbstractFile.write_to_file(content, file.final_destination_path)
      end
    end
  end
end
