# encoding: utf-8

module Epuber
  module DSL
    module AttributeSupport
      # Method to create attribute for DSL object
      #
      # @example
      #     attribute :name
      #     attribute :title, required: true, inherited: true
      #
      # @param name [Symbol] attribute name
      # @param options [Dict]
      #
      # @see Epuber::DSL::Attribute
      #
      def attribute(name, options = {})
        attr = Attribute.new(name, options)

        @attributes       ||= {}
        @attributes[name] = attr

        define_method_attr(name, attr)
      end

      def find_root(instance)
        return unless instance.respond_to?(:parent)

        if instance.parent.nil?
          instance
        else
          find_root(instance.parent)
        end
      end

      # @param name [Symbol]
      # @param attr [Attribute]
      #
      def define_method_attr(name, attr)
        key = name

        # define normal getter
        define_method(key) do
          value = @attributes_values[key]

          if !value.nil?
            value
          elsif attr.inherited? && respond_to?(:parent) && parent
            parent.send(key)
          elsif !attr.default_value.nil?
            root_obj = self.class.find_root(self) || self
            root_obj.send(attr.writer_name, attr.default_value)
          end
        end

        # define normal setter
        define_method(attr.writer_name) do |value|
          if attr.singularize?
            array_value = if value.is_a? Array
                            value
                          else
                            [value]
                          end

            mapped = array_value.map { |one_value| attr.converted_value(one_value) }

            @attributes_values[key] = mapped
          else
            @attributes_values[key] = attr.converted_value(value)
          end
        end

        return unless attr.singularize?

        # define singular methods
        singular_key = key.to_s.singularize.to_sym

        define_method(singular_key) do
          value = @attributes_values[key]

          if attr.singularize? && value.is_a?(Array)
            value.first
          else
            value
          end
        end

        define_method(attr.writer_singular_form) do |value|
          if attr.singularize?
            array_value = if value.is_a?(Array)
                            value
                          else
                            [value]
                          end

            @attributes_values[key] = array_value.map { |one_value| attr.converted_value(one_value) }
          else
            @attributes_values[key] = attr.converted_value(value)
          end
        end
      end
    end
  end
end
