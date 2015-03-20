# encoding: utf-8

module Epuber
  class Book
    class Contributor
      # File-as of contributor used in .opf file
      # @return [String] pretty name
      #
      attr_reader :file_as

      # Pretty name of contributor used in .opf file and copyright page
      # @return [String] pretty name
      #
      attr_reader :pretty_name

      # Role of contributor
      # @return [String] role
      #
      attr_reader :role


      # @param [String] pretty_name  pretty name of contributor
      # @param [String] file_as      file as of contributor
      # @param [String] role         contributor role
      #
      def initialize(pretty_name, file_as, role)
        @file_as     = file_as
        @pretty_name = pretty_name
        @role        = role
      end

      # Creates new instance of Contributor dependent on obj content
      #
      # @param obj [Hash<Symbol, String>, Array<Hash<Symbol,String>, String, Array<String>] input object
      # @param role [String] role of contributor
      #
      # @return [Contributor]
      #
      def self.from_obj(obj, role)
        if obj.is_a?(String)
          components = obj.split(' ')
          if components.length >= 2
            NormalContributor.new(components.first(components.length - 1).join(' '), components.last, role)
          end
        elsif obj.is_a?(Hash)
          if obj.key?(:first_name)
            NormalContributor.new(obj[:first_name], obj[:last_name], role)
          elsif obj.key?(:file_as)
            Contributor.new(obj[:pretty_name], obj[:file_as], role)
          end
        end
      end
    end

    class NormalContributor < Contributor
      # @return [String] first name of contributor
      #
      attr_accessor :first_name

      # @return [String] last name of contributor
      #
      attr_accessor :last_name


      # @param [String] first_name first name of contributor
      # @param [String] last_name last name of contributor
      # @param [String] role contributor role
      #
      def initialize(first_name, last_name, role)
        super(nil, nil, role)

        @first_name = first_name
        @last_name  = last_name
      end


      # @return [String]
      #
      def pretty_name
        "#{@first_name} #{@last_name}"
      end

      # @return [String]
      #
      def file_as
        "#{@last_name.upcase}, #{@first_name}"
      end
    end
  end
end
