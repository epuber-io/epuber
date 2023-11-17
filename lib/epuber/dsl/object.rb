# frozen_string_literal: true

require_relative 'attribute'
require_relative 'attribute_support'

require 'active_support'
require 'active_support/core_ext/string/inflections'


module Epuber
  module DSL
    class Object
      class ValidationError < StandardError; end

      # @return [String, nil]
      #
      attr_reader :file_path

      def initialize
        super
        @attributes_values = {}
        @file_path = nil
      end

      # @return [String]
      #
      def to_s
        "<#{self.class} #{@attributes_values}>"
      end

      # @return nil
      #
      def freeze
        super
        @attributes_values.freeze
      end

      # Validates all values of attributes, if there is some error, StandardError will be raised
      #
      # @note it only check for required values for now
      #
      # @return nil
      #
      def validate
        self.class.dsl_attributes.each do |key, attr|
          value = @attributes_values[key] || attr.converted_value(attr.default_value)

          attr.validate_type(value)

          next unless attr.required? && value.nil?

          if attr.singularize?
            raise ValidationError, "missing required attribute `#{key.to_s.singularize}|#{key}`"
          else
            raise ValidationError, "missing required attribute `#{key}`"
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
        from_string(::File.new(file_path).read, file_path)
      end

      # Creates new instance by parsing ruby code from string
      #
      # @param string [String]
      #
      # @return [Self]
      #
      def self.from_string(string, file_path = nil)
        # rubocop:disable Lint/Eval
        obj = if file_path
                eval(string, nil, file_path)
              else
                eval(string)
              end
        # rubocop:enable Lint/Eval

        unless obj.is_a?(self)
          msg = "Invalid object #{obj.class}, expected object of class #{self}"

          if file_path
            msg += ", loaded from file #{file_path}"

          end

          raise StandardError, msg
        end

        obj.instance_eval { @file_path = file_path }
        obj
      end

      # @return [Bool] is created from file
      #
      def from_file?
        !file_path.nil?
      end

      # --------------------------------------------------- #

      # @group Attributes

      protected

      extend AttributeSupport

      class << self
        # @return [Hash<Symbol, Attribute>] The attributes of the class.
        #
        attr_accessor :attributes
      end

      # @return [Hash<Symbol, Any>]
      #
      attr_accessor :attributes_values

      # Raise exception when there is used some unknown method or attribute
      #
      # This is just for creating better message in raised exception
      #
      # @return nil
      #
      def method_missing(name, *args)
        if /([^=]+)=?/ =~ name
          attr_name = $1
          location = caller_locations.first
          raise NameError,
                "Unknown attribute or method `#{attr_name}` for class `#{self.class}` in file `#{location.path}:#{location.lineno}`"
        else
          super
        end
      end
    end
  end
end
