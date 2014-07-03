require_relative 'dsl/object'
require_relative 'book/vendor/contributor'

module Epuber

	class StandardError < ::StandardError; end

	class Book < DSLObject

		def initialize
			super

			yield self if block_given?

			# convert attributes to corresponding classes
			__finish_parsing
		end


		private

		def __finish_parsing
			if self.author
				self.author = Contributor.from_ruby(self.author, 'aut')
			end
		end





		#------------- DSL attributes ----------------------------------------------------------------------------------

		public

		# @return [String] title of book
		#
		attribute :title,
				  :required => true

		# @return [String] subtitle of book
		#
		attribute :subtitle

		# @return [Array{Contributor}] authors of book
		#
		attribute :authors,
				  :types       => [ Contributor, NormalContributor ],
				  :container   => Array,
				  :required    => true,
				  :singularize => true

		# @return [String] publisher name
		#
		# TODO add tests
		#
		attribute :publisher


		# TODO language
		# TODO print_isbn
		# TODO toc
		# TODO landmarks
		# TODO cover page
		# TODO other files
		# TODO footnotes customization
	end
end
