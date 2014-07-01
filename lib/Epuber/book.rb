require_relative 'dsl/object'
require_relative 'book/vendor/contributor'

module Epuber

	class StandardError < ::StandardError; end

	class Book < DSLObject

		def initialize
			super

			yield self

			# convert attributes to corresponding classes
			__finish_parsing

			# validate attributes (required, ...)
			validate_attributes

			# freeze object, so you cannot modify him
			freeze
		end


		private

		def __finish_parsing
			if self.author
				self.author = Contributor.create(self.author, 'aut')
			end
		end




		public


		#------------- DSL attributes ----------------------------------------------------------------------------------

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

	end
end
