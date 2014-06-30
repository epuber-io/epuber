require_relative 'book/dsl'

module Epuber
	class Book
		include Epuber::Book::DSL::AttributeSupport

		def initialize
			@attributes_values = {}

			yield self if block_given?
		end

		def to_s
			super.to_s + @attributes_values.to_s
		end

		DSL.attributes.each do |key, attr|

			define_method(key.to_sym) do
				return @attributes_values[key.to_sym]
			end

			define_method(attr.writer_name) do |value|
				@attributes_values[key.to_sym] = value
			end
		end
	end
end
