
require_relative 'object'

module Epuber
	class DSLTreeObject < DSLObject

		# @param [DSLTreeObject] parent
		#
		def initialize(parent = nil)
			super()

			@parent = parent
			@child_items = []

			unless parent.nil?
				parent.child_items << self
			end
		end

		# @return [DSLTreeObject] reference to parent
		#
		attr_reader :parent

		# @return [Array<DSLTreeObject>] child items
		#
		attr_reader :child_items


		protected
			attr_writer :parent
			attr_writer :child_items
		public


		# @return [Bool] reciever is root
		#
		def root?
			@parent.nil?
		end



		def create_child_item(*args)
			child = self.class.new(*args)

			yield child if block_given?

			child.parent = self
			@child_items << child

			child
		end
	end
end
