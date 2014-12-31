# encoding: utf-8

require 'date'

require 'active_support/core_ext/string/inflections'

module Epuber
  module DSL
    # Stores the information of an attribute. It also provides logic to implement any required logic.
    #
    class Attribute
      # @return [Symbol] name of attribute
      #
      attr_reader :name

      # rubocop:disable Metrics/ParameterLists

      # Returns a new attribute initialized with the given options.
      #
      # @param name [Symbol]
      #
      # @see #name
      #
      # @raise    If there are unrecognized options.
      #
      def initialize(name, inherited: false,
                     root_only: false,
                     required: false,
                     singularize: false,
                     file_patterns: false,
                     container: nil,
                     keys: nil,
                     default_value: nil,
                     auto_convert: {},
                     types: nil)

        @name = name

        @inherited     = inherited
        @root_only     = root_only
        @required      = required
        @singularize   = singularize
        @file_patterns = file_patterns
        @container     = container
        @keys          = keys
        @default_value = default_value
        @auto_convert  = auto_convert
        @types         = if !types.nil?
                           types
                         elsif @default_value
                           [@default_value.class]
                         else
                           [String]
                         end
      end

      # rubocop:enable Metrics/ParameterLists

      # @return [String] A string representation suitable for UI.
      #
      def to_s
        "Attribute `#{name}`"
      end

      # @return [String] A string representation suitable for debugging.
      #
      def inspect
        "<#{self.class} name=#{name} types=#{types}>"
      end

      #---------------------------------------------------------------------#

      # @!group Options

      # @return [Array<Class>] the list of the classes of the values supported by the attribute writer.
      #         If not specified defaults to [String].
      #
      attr_reader :types

      # @return [Array<Class>] the list of the classes of the values supported by the attribute, including
      #         the container.
      #
      def supported_types
        @supported_types ||= @types.dup.push(container).compact
      end

      # @return [Class] if defined it can be [Array] or [Hash]. It is used as default initialization value
      #         and to automatically wrap other values to arrays.
      #
      attr_reader :container

      # @return [Array, Hash] the list of the accepted keys for an attribute wrapped by a Hash.
      #
      # @note   A hash is accepted to group the keys associated only with certain keys (see the source
      #         attribute of a Book).
      #
      attr_reader :keys

      # @return [Object] if the attribute follows configuration over convention it can specify a default value.
      #
      # @note   The default value is not automatically wrapped and should be specified within the container
      #         if any.
      #
      attr_reader :default_value

      # @return [Bool] whether the specification should be considered invalid if a value for the attribute
      #         is not specified.
      #
      attr_reader :required
      alias_method :required?, :required

      # @return [Bool] whether the attribute should be specified only on the root specification.
      #
      attr_reader :root_only
      alias_method :root_only?, :root_only


      # @return [Bool] whether there should be a singular alias for the attribute writer.
      #
      attr_reader :singularize
      alias_method :singularize?, :singularize

      # @return [Bool] whether the attribute describes file patterns.
      #
      # @note   This is mostly used by the linter.
      #
      attr_reader :file_patterns
      alias_method :file_patterns?, :file_patterns

      # @return [Bool] defines whether the attribute reader should join the values with the parent.
      #
      # @note   Attributes stored in wrappers are always inherited.
      #
      def inherited?
        !root_only? && @inherited
      end

      #---------------------------------------------------------------------#

      # @return [String] the name of the setter method for the attribute.
      #
      def writer_name
        "#{name}="
      end

      # @return [String] an aliased attribute writer offered for convenience on the DSL.
      #
      def writer_singular_form
        "#{name.to_s.singularize}=" if singularize?
      end

      #---------------------------------------------------------------------#

      # @!group Values validation

      # Validates the value for an attribute. This validation should be performed before the value is
      # prepared or wrapped.
      #
      # @note   The this is called before preparing the value.
      #
      # @raise  If the type is not in the allowed list.
      #
      # @return [void]
      #
      def validate_type(value)
        return if value.nil?
        return if supported_types.any? { |klass| value.class == klass }

        raise StandardError, "Non acceptable type `#{value.class}` for #{self}. Allowed types: `#{types.inspect}`"
      end

      # Validates a value before storing.
      #
      # @raise If a root only attribute is set in a subspec.
      #
      # @raise If a unknown key is added to a hash.
      #
      # @return [void]
      #
      def validate_for_writing(spec, value)
        if root_only? && !spec.root?
          raise StandardError, "Can't set `#{name}` attribute for subspecs (in `#{spec.name}`)."
        end

        if keys
          value.keys.each do |key|
            unless allowed_keys.include?(key)
              raise StandardError, "Unknown key `#{key}` for #{self}. Allowed keys: `#{allowed_keys.inspect}`"
            end
          end
        end

        # @return [Array] the flattened list of the allowed keys for the hash of a given specification.
        #
        def allowed_keys
          if keys.is_a?(Hash)
            keys.keys.concat(keys.values.flatten.compact)
          else
            keys
          end
        end
      end


      #---------------------------------------------------------------------#

      # @!group Automatic conversion

      # Converts value to compatible type of attribute
      #
      # Can be configured with option :auto_convert
      #    Supports conversion from type to type, eg `{ String => Fixnum }`
      #        also from types to type eg `{ [String, Date] => Fixnum }`
      #    Supports custom conversion with Proc, eg `{ String => lambda { |value| value.to_s } }`
      #        also with multiple types
      #
      def converted_value(value)
        begin
          validate_type(value)
        rescue StandardError
          raise if @auto_convert.nil?

          begin
            dest_class = @auto_convert[value.class]

            if dest_class.nil?
              array_keys           = @auto_convert.select { |k, _v| k.is_a?(Array) }
              array_keys_with_type = array_keys.select { |k, _v| k.include?(value.class) }

              if array_keys_with_type.count > 0
                dest_class = array_keys_with_type.values.first
              end
            end

            if dest_class.is_a?(Proc)
              return dest_class.call(value)
            elsif dest_class.respond_to?(:parse)
              return dest_class.parse(value)
            else
              return dest_class.new(value)
            end

          rescue
            raise StandardError, "Unknown auto-conversion from class #{value.class} into class #{dest_class.class}"
          end
        end

        value
      end
    end
  end
end
