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
        @all_files = YAML.load_file(path)
      rescue
        @all_files = {}
      end

      # @param [String] file_path
      #
      def changed?(file_path)
        stat = @all_files[file_path]
        return true if stat.nil?

        stat != FileStat.new(file_path)
      end

      # @param [String] file_path
      #
      def up_to_date?(file_path)
        !changed?(file_path)
      end

      # @param [String] file_path
      #
      def update_metadata(file_path)
        @all_files[file_path] = FileStat.new(file_path)
      end

      # @param [Array<String>] file_paths
      #
      def cleanup(file_paths)
        to_remove = @all_files.keys - file_paths
        to_remove.each { |key| @all_files.delete(key) }
      end

      def save_to_file(path = store_file_path)
        File.write(path, @all_files.to_yaml)
      end

    end
  end
end
