# encoding: utf-8

require_relative '../book/file_request'


module Epuber
  class Compiler
    class File
      # @return [Epuber::Book::FileRequest] original file request
      #
      attr_reader :file_request


      # @return [String] absolute destination path
      #
      attr_accessor :destination_path

      # @return [String] destination path in package, is used only for resolving destination path
      #
      attr_accessor :package_destination_path

      # @return [Symbol] group of this file (:text, :image, :font, ...)
      #
      attr_accessor :group

      # @return [String] content of this file, it can be used for creating file with generated content
      #
      attr_accessor :content

      # @return [Set<String>] list of properties
      #
      attr_accessor :properties

      # @return [String] resolved source path to source file
      #
      attr_accessor :source_path


      # @param file_request_or_path [String, Epuber::Book::FileRequest]
      # @param [Symbol] group group of file, see Epuber::Compiler::FileFinder::GROUP_EXTENSIONS
      # @param [Array<Symbol>, Set<Symbol>] properties list of properties, TODO add list of supported properties, and validate them
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

      # @param [Self] other
      #
      # @return [Bool]
      #
      def eql?(other)
        self == other
      end

      # @return [Numeric]
      #
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
      # @return [Bool]
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


      # @param property [String, Symbol]
      #
      # @return [nil]
      #
      def add_property(property)
        @properties << property
      end

      def group
        @group || file_request.group
      end
    end
  end
end
