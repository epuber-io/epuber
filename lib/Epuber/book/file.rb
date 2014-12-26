
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

      # @return [Array<String>]
      #
      attr_accessor :properties

      # @return [String]
      #
      attr_accessor :real_source_path


      def initialize(source_path, group: nil)
        @source_path_pattern = source_path

        @only_one = true
        @group = group
        @properties = []
      end

      # @param property [String]
      #
      def add_property(property)
        @properties << property unless @properties.include?(property)
      end

      # @param other [String, Epuber::Book::File]
      #
      def ==(other)
        if other.is_a?(String)
          @source_path_pattern == other
        else
          @source_path_pattern == other.source_path_pattern
        end
      end
    end
  end
end
