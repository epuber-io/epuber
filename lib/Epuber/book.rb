require_relative 'dsl/object'
require_relative 'book/vendor/contributor'

module Epuber
	class Book < DSLObject

		def initialize
			super
			yield self if block_given?
		end


		#---------------------------------------------------------------------------------------------------------------

		# @return [String] title of book
		#
		attribute :title,
				  :required => true

		# @return [String] subtitle of book
		#
		attribute :subtitle

		# @return [Array<Contributor>] authors of book
		#
		attribute :authors,
				  :types       => [Contributor],
				  :container   => Hash,
				  :required    => true,
				  :singularize => true

		# @return [String] publisher name
		#
		attribute :publisher


		#---------------------------------------------------------------------------------------------------------------
		define_properties_methods
	end
end
