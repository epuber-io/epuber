require_relative 'attribute'
require_relative 'attribute_support'

require 'active_support/core_ext/string/inflections'


module Epuber
  module DSL
    class Object

      # ------------ DSL attributes ----------------------
      protected

      extend Object::AttributeSupport

      class << self
        # @return [Hash<Symbol, Attribute>] The attributes of the class.
        #
        attr_accessor :attributes
      end

      # @return [Hash<Symbol, Any>]
      #
      attr_accessor :attributes_values


      public

      # Validates all values of attributes, if there is some error, StandardError will be raised
      #
      # @note it only check for required values for now
      #
      def validate
        self.class.attributes.each do |key, attr|

          value = @attributes_values[key] || attr.converted_value(attr.default_value)

          attr.validate_type(value)

          if attr.required? and value.nil?
            if attr.singularize?
              raise StandardError, "missing required attribute `#{key.to_s.singularize}|#{key}`"
            else
              raise StandardError, "missing required attribute `#{key}`"
            end
          end
        end
      end

      # Creates new instance by parsing ruby code from file
      #
      # @param file_path [String]
      #
      # @return [Self]
      #
      def self.from_file(file_path)
        self.from_string(::File.new(file_path).read, file_path)
      end

      # Creates new instance by parsing ruby code from string
      #
      # @param string [String]
      #
      # @return [Self]
      #
      def self.from_string(string, file_path = nil)
        if file_path
          eval(string, nil, file_path)
        else
          eval(string)
        end
      end


      # ------------ Override methods ----------------------
      public

      def initialize
        super
        @attributes_values = {}
      end

      def to_s
        "<#{self.class} #{@attributes_values}>"
      end

      def freeze
        super
        @attributes_values.freeze
      end

    end
  end
end
