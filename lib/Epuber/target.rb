
require_relative 'dsl/tree_object'

module Epuber
	class Target < DSLTreeObject

		# @param [Target] parent
		# @param [String] name
		#
		def initialize(parent = nil, name)
			super(parent)

			@name = name
		end

		# @return [String] target name
		#
		attr_reader :name

		# @return [Array<Target>] list of sub targets
		#
		def sub_targets
			child_items
		end


		# Create new sub_target with name
		#
		# @param [String] name
		#
		# @return [Target] new created sub target
		#
		def sub_target(name)
			child = create_child_item(name)

			yield child if block_given?

			child
		end


		#----------------------- DSL items ---------------------------

		# @return [String] version of result epub
		#
		attribute :epub_version,
				  :required => true

		# @return [String] isbn of epub
		#
		attribute :isbn,
				  :required => true

		# @return [String] target will use custom font (for iBooks only)
		#
		attribute :custom_fonts,
				  :types => [ TrueClass, FalseClass ]

	end
end
