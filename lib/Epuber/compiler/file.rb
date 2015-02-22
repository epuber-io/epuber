# encoding: utf-8

module Epuber
  class Compiler
    class File
      # require_relative '../book/file_request'

      # @return [Epuber::Book::FileRequest]
      #
      attr_reader :file_request


      # @return [String]
      #
      attr_accessor :destination_path

      # @return [String]
      #
      attr_accessor :package_destination_path

      # @return [String]
      #
      attr_accessor :mime_type

      # @return [Symbol]
      #
      attr_accessor :group

      # @return [String]
      #
      attr_accessor :content

      # @return [Set<String>]
      #
      attr_accessor :properties

      # @return [String]
      #
      attr_accessor :source_path


      # @param file_request_or_path [String, Epuber::Book::FileRequest]
      #
      def initialize(file_request_or_path, group: nil, properties: [])
        @file_request = if file_request_or_path.is_a?(Epuber::Book::FileRequest)
                          file_request_or_path
                        elsif file_request_or_path.is_a?(String)
                          Epuber::Book::FileRequest.new(file_request_or_path)
                        end

        @properties = if @file_request.nil?
                        properties.to_set
                      else
                        (@file_request.properties + properties).to_set
                      end

        @group            = group
        @source_path      = nil
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
        if !@file_request.nil?
          @file_request.hash
        elsif !@destination_path.nil?
          @destination_path.hash
        elsif !@source_path.nil?
          @source_path.hash
        end
      end

      # @param other [String, Epuber::Book::FileRequest]
      #
      def ==(other)
        if other.is_a?(String) || other.is_a?(Epuber::Book::FileRequest)
          @file_request == other
        else
          if !@destination_path.nil? && !other.destination_path.nil?
            @destination_path == other.destination_path
          elsif !@source_path.nil? && !other.source_path.nil?
            @source_path == other.source_path
          else
            @source_path == other.source_path && @group == other.group
          end
        end
      end

      def group
        @group || file_request.group
      end

      # @param file [Epuber::Book::File]
      #
      # TODO: rename to merge!
      #
      def merge_with(file)
        @properties = file.properties
      end
    end
  end
end
