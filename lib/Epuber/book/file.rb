
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



      attr_accessor :content


      # @return [String]
      #
      attr_accessor :real_source_path


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
