require_relative 'attribute'
require_relative 'attribute_support'

require 'active_support/core_ext/string/inflections'


module Epuber
	class DSLObject

		# ------------ DSL attributes ----------------------
		protected

		extend DSLObject::AttributeSupport

		class << self
			# @return [Hash<Symbol, Attribute>] The attributes of the class.
			#
			attr_accessor :attributes
		end

		# @return [Hash<Symbol, Any>]
		#
		attr_accessor :attributes_values


		# Validates all values of attributes
		#
		# @note it only check for required values for now
		#
		def validate_attributes
			self.class.attributes.each do |key, attr|

				value = @attributes_values[key]

				if attr.required? and value.nil?
					if attr.singularize?
						raise StandardError, "missing required attribute `#{key.to_s.singularize}|#{key}`"
					else
						raise StandardError, "missing required attribute `#{key}`"
					end
				end
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
