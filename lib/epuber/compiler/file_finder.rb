# encoding: utf-8

require 'unicode_normalize'


module Epuber
  class Compiler
    class FileFinder
      class FileNotFoundError < ::StandardError
        # @return [String]
        #
        attr_reader :pattern

        # @param [String] pattern
        #
        def initialize(pattern)
          @pattern = pattern
        end
      end

      class MultipleFilesFoundError < ::StandardError
        # @return [Array<String>]
        #
        attr_reader :files_paths

        # @return [String]
        #
        attr_reader :pattern

        # @param [String] pattern
        # @param [Array<String>] files_paths
        #
        def initialize(pattern, files_paths)
          @pattern = pattern
          @files_paths = files_paths
        end
      end

      BINARY_EXTENSIONS = %w(.png .jpeg .jpg .otf .ttf)
      STATIC_EXTENSIONS = BINARY_EXTENSIONS + %w(.css .js)

      GROUP_EXTENSIONS = {
          text:   %w(.xhtml .html .bade),
          image:  %w(.png .jpg .jpeg),
          font:   %w(.otf .ttf),
          style:  %w(.css .styl),
          script: %w(.js),
      }

      EXTENSIONS_RENAME = {
          '.styl'   => '.css',

          '.bade'   => '.xhtml',
      }

      # @return [String] path where should look for source files
      #
      attr_reader :source_path


      # @param [String] source_path
      #
      def initialize(source_path)
        @source_path = source_path.unicode_normalize.freeze
        @source_path_abs_pathname = Pathname.new(::File.expand_path(@source_path))
      end

      # @param [String] pattern  pattern of the desired files
      #
      # @return [Array<String>] list of founded files
      #
      def find_files(pattern)
        full_pattern = ::File.expand_path(pattern, source_path)
        file_paths = Dir.glob(full_pattern)

        file_paths.map do |path|
          Pathname(path.unicode_normalize).relative_path_from(@source_path_abs_pathname)
        end
      end
    end
  end
end
