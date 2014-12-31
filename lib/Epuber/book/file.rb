# encoding: utf-8

module Epuber
  module Book
    class File
      # @return [String]
      #
      attr_accessor :destination_path

      # @return [String]
      #
      attr_accessor :source_path_pattern

      # @return [String]
      #
      attr_accessor :mime_type

      # @return [Symbol]
      #
      attr_accessor :group

      # @return [String]
      #
      attr_accessor :content

      # When looking for file, the resulted list should contain only one file
      #
      # Default: true
      #
      # @return [Bool]
      #
      attr_accessor :only_one

      # @return [Set<String>]
      #
      attr_accessor :properties

      # @return [String]
      #
      attr_accessor :real_source_path


      def initialize(source_path, group: nil, properties: [])
        @source_path_pattern = source_path

        @only_one = true
        @group = group
        @properties = properties.to_set
        @real_source_path = nil
        @destination_path = nil
      end

      # @param property [String]
      #
      def add_property(property)
        @properties << property
      end

      def eql?(other)
        self == other
      end

      def hash
        if !@destination_path.nil?
          @destination_path.hash
        elsif !@real_source_path.nil?
          @real_source_path.hash
        else
          @source_path_pattern.hash ^ @group.hash
        end
      end

      # @param other [String, Epuber::Book::File]
      #
      def ==(other)
        if other.is_a?(String)
          @source_path_pattern == other
        else
          if !@destination_path.nil? && !other.destination_path.nil?
            @destination_path == other.destination_path
          elsif !@real_source_path.nil? && !other.real_source_path.nil?
            @real_source_path == other.real_source_path
          else
            @source_path_pattern == other.source_path_pattern && @group == other.group
          end
        end
      end

      # @param file [Epuber::Book::File]
      #
      def merge_with(file)
        @properties = file.properties
      end
    end
  end
end
