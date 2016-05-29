# encoding: utf-8
# frozen_string_literal: true

module Epuber
  class Compiler
    class FileStat
      # @return [Date]
      #
      attr_reader :mtime

      # @return [Date]
      #
      attr_reader :ctime

      # @return [Fixnum]
      #
      attr_reader :size

      # @return [String]
      #
      attr_reader :file_path

      # @return [String]
      #
      attr_reader :dependency_paths

      # @param [String] path
      # @param [File::Stat] stat
      #
      def initialize(path, stat = nil, dependency_paths: [])
        @file_path = path

        stat ||= File.stat(path)
        @mtime = stat.mtime
        @ctime = stat.ctime
        @size = stat.size

        @dependency_paths = dependency_paths
      end

      # @param [String] path
      #
      def add_dependency!(path)
        @dependency_paths << path
      end

      # @param [Array<String>] paths
      #
      def keep_dependencies!(paths)
        to_delete = (dependency_paths - paths)
        @dependency_paths -= to_delete
      end

      # @param [FileStat] other
      #
      # @return [Bool]
      #
      def ==(other)
        raise AttributeError, "other must be class of #{self.class}" unless other.is_a?(FileStat)

        file_path == other.file_path &&
             size == other.size &&
            mtime == other.mtime &&
            ctime == other.ctime
      end
    end
  end
end
