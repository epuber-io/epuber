module Epuber
	class DSLObject
		module AttributeSupport

			def attribute(name, options = {})
				store_attribute(name, options)
			end

			def store_attribute(name, options)
				attr              = Attribute.new(name, options)
				@attributes       ||= {}
				@attributes[name] = attr

				define_method_attr(name, attr)
			end

			def define_method_attr(name, attr)

				key = name

				define_method(key) do
					return @attributes_values[key]
				end

				define_method(attr.writer_name) do |value|
					@attributes_values[key] = value
				end

				if attr.singularize?
					original_key = key
					key          = key.to_s.singularize.to_sym

					define_method(key) do
						return @attributes_values[original_key]
					end

					define_method(attr.writer_singular_form) do |value|
						@attributes_values[original_key] = value
					end
				end
			end
		end
	end
end
