# frozen_string_literal: true

require 'yaml'
require_relative 'vendor/version'

module Epuber
  class Lockfile
    attr_accessor :defined_from_file

    # @param [Hash] data
    #
    def initialize(data = {})
      @internal_data = data
    end

    # Load existing lockfile from given path, or create new one. You can define default attributes in block.
    #
    # @return [self]
    #
    def self.from_file(file_path)
      if File.exists?(file_path)
        hash = YAML.safe_load(File.read(file_path))
      else
        hash = {}
      end

      # backward compatibility for version 0.5 and older
      if hash.include?('version')
        hash['epuber_version'] = hash.delete('version')
      end

      inst = self.new(hash)
      inst.defined_from_file = file_path
      yield inst if hash.empty? && block_given?
      inst
    end

    # @return nil
    #
    def write_to_file
      return if defined_from_file.nil?

      File.write(defined_from_file, @internal_data.to_yaml)
    end

    # @return [Epuber::Version]
    #
    def epuber_version
      Version.new(@internal_data['epuber_version'])
    end

    # @param [Epuber::Version] new_version
    #
    def epuber_version=(new_version)
      @internal_data['epuber_version'] = new_version.to_s
    end

    # @return [Epuber::Version]
    #
    def bade_version
      value = @internal_data['bade_version']
      value = Version.new(value) unless value.nil?
      value
    end

    # @param [Epuber::Version] new_version
    #
    def bade_version=(new_version)
      @internal_data['bade_version'] = new_version
    end
  end
end
