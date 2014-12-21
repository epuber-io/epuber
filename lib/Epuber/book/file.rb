
module Epuber
  module Book
    class File

      # @return [String]
      #
      attr_accessor :destination_path

      # @return [String]
      #
      attr_accessor :source_path

      # @return [String]
      #
      attr_accessor :mime_type

      # @return [String]
      #
      attr_accessor :group_name

      def initialize(source_path)
        @source_path = source_path
      end

      # @param other [Epuber::Book::File]
      #
      def ==(other)
        @source_path == other.source_path
      end
    end
  end
end
