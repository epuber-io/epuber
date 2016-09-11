# encoding: utf-8
# frozen_string_literal: true

require 'yaml'


module Epuber
  class Compiler
    require_relative 'file_stat'

    class FileDatabase

      # @return [Hash<String, Epuber::Compiler::FileStat>]
      #
      attr_accessor :all_files

      # @return [String]
      #
      attr_reader :store_file_path

      # @param [String] path
      #
      def initialize(path)
        @store_file_path = path
        @all_files = YAML.load_file(path) || {}
      rescue
        @all_files = {}
      end

      # @param [String] file_path
      #
      def changed?(file_path, transitive: true, default_value: true)
        stat = @all_files[file_path]
        return default_value if stat.nil?

        result = (stat != FileStat.new(file_path))

        if transitive
          result ||= stat.dependency_paths.any? do |path|
            changed?(path, transitive: transitive, default_value: false)
          end
        end

        result
      end

      # @param [String] file_path
      #
      # @return [FileStat]
      #
      def file_stat_for(file_path)
        @all_files[file_path]
      end

      # @param [String] file_path
      #
      def up_to_date?(file_path, transitive: true)
        !changed?(file_path, transitive: transitive)
      end

      # @param [String] file_path
      #
      def update_metadata(file_path, load_stats: true)
        old_stat = @all_files[file_path]
        old_dependencies = old_stat ? old_stat.dependency_paths : []

        @all_files[file_path] = FileStat.new(file_path, load_stats: load_stats, dependency_paths: old_dependencies)
      end

      def update_all_metadata
        @all_files.each do |file_path, _|
          update_metadata(file_path)
        end
      end

      # @param [Array<String>, String] file_path  path to file that will be dependent on
      # @param [String] to  path to original file, that will has new dependency
      #
      def add_dependency(file_path, to: nil)
        raise ArgumentError, ':to is required' if to.nil?

        file_paths = Array(file_path)

        to_stat = @all_files[to]
        raise ArgumentError, ":to (#{to}) file is not in database" if to_stat.nil?

        to_stat.add_dependency!(file_paths)

        begin
          file_paths.each do |path|
            update_metadata(path, load_stats: false) if @all_files[path].nil?
          end
        rescue Errno::ENOENT
          # no action, valid case where dependant file does not exist
        end
      end

      # @param [Array<String>] file_paths
      #
      def cleanup(file_paths)
        to_remove = @all_files.keys - file_paths
        to_remove.each { |key| @all_files.delete(key) }

        @all_files.each do |_, stat|
          _cleanup_stat_dependency_list(file_paths, stat)
        end
      end

      # @param [String] path
      #
      def save_to_file(path = store_file_path)
        FileUtils.mkdir_p(File.dirname(path))

        File.write(path, @all_files.to_yaml)
      end


      # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

      private

      # @param [Array<String>] file_paths
      # @param [FileStat] stat
      #
      def _cleanup_stat_dependency_list(file_paths, stat)
        stat.keep_dependencies!(file_paths)

        stat.dependency_paths.each do |path|
          next_stat = @all_files[path]
          next if next_stat.nil?

          _cleanup_stat_dependency_list(file_paths, next_stat)
        end
      end

    end
  end
end
