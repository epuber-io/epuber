# encoding: utf-8

module Epuber
  class Book
    class FileRequest
      # @return [String]
      #
      attr_accessor :source_pattern

      # @return [Symbol]
      #
      attr_accessor :group

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


      def initialize(source_pattern, group: nil, properties: [])
        @source_pattern = source_pattern
        @only_one       = true
        @group          = group
        @properties     = properties.to_set
      end

      def eql?(other)
        self == other
      end

      def hash
        @source_pattern.hash ^ @group.hash ^ @only_one.hash
      end

      # @param other [String, self]
      #
      def ==(other)
        if other.is_a?(String)
          @source_pattern == other
        else
          @source_pattern == other.source_pattern && @group == other.group && @only_one == other.only_one
        end
      end
    end
  end
end
