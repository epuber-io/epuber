require_relative 'attribute'
require_relative 'attribute_support'
require 'active_support/core_ext/string/inflections'

module Epuber
	class DSLObject
		extend DSLObject::DSL::AttributeSupport

		# @return [Hast<Symbol, Attribute>]
		#
		attr_accessor :attributes_values


		def initialize
			super

			@attributes_values = {}
		end

		def to_s
			"<#{self.class.name} #{@attributes_values.to_s}>"
		end

		# Defines setters and getters for properties
		#
		def self.define_properties_methods
			@attributes.each do |key, attr|
				key = key.to_sym

				define_method(key) do
					return @attributes_values[key]
				end

				define_method(attr.writer_name) do |value|
					@attributes_values[key] = value
				end

				if attr.singularize?
					key = key.to_s.singularize.to_sym

					define_method(key) do
						return @attributes_values[key]
					end

					define_method(attr.writer_singular_form) do |value|
						@attributes_values[key] = value
					end
				end
			end
		end
	end
end
