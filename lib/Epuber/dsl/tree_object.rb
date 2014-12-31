# encoding: utf-8

require_relative 'object'

module Epuber
  module DSL
    class TreeObject < Object
      # @param [DSLTreeObject] parent
      #
      def initialize(parent = nil)
        super()

        @parent      = parent
        @child_items = []

        parent.child_items << self unless parent.nil?
      end

      # @return [TreeObject] reference to parent
      #
      attr_reader :parent

      # @return [Array<self.class>] child items
      #
      attr_reader :child_items


      protected

      attr_writer :parent
      attr_writer :child_items

      public


      # @return [Bool] receiver is root
      #
      def root?
        @parent.nil?
      end


      def validate
        super
        child_items.each(&:validate)
      end


      # @return [self.class]
      #
      def create_child_item(*args)
        child = self.class.new(*args)

        child.parent = self
        @child_items << child

        yield child if block_given?

        child
      end

      def create_child_items
        yield self if block_given?
      end
    end
  end
end
