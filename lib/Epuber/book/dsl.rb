require_relative 'dsl/attribute'
require_relative 'dsl/attribute_support'

require_relative 'vendor/contributor'


module Epuber
	class Book
		module DSL
			extend Epuber::Book::DSL::AttributeSupport

			# @return [String] title of book
			#
			attribute :title,
					  :required => true

			# @return [String] subtitle of book
			#
			attribute :subtitle


			# @return [Array<Contribute>] authors of book
			#
			attribute :authors,
					  :types       => [Contributor],
					  :container   => Hash,
					  :required    => true,
					  :singularize => true


			# @return [String] publisher name
			#
			attribute :publisher

		end
	end
end
