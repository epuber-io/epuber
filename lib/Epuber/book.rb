require_relative 'dsl/object'

require_relative 'book/vendor/contributor'
require_relative 'target'

module Epuber

	class StandardError < ::StandardError; end

	class Book < DSLObject

		def initialize
			super

			@default_target = Target.new(nil)

			yield self if block_given?

			# convert attributes to corresponding classes
			__finish_parsing
		end


		def self.from_string(string, filepath = nil)
			if filepath
				eval(string, nil, filepath)
			else
				eval(string)
			end
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
		attribute :publisher

		# @return [String] language of this book
		#
		attribute :language

		# @return [String] isbn of this book
		#
		attribute :isbn

		# @return [String] isbn of printed book
		#
		attribute :print_isbn



		# TODO toc
		# TODO landmarks
		# TODO cover page
		# TODO other files
		# TODO footnotes customization
		# TODO custom metadata
	end
end
