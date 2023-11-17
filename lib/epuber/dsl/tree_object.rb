# frozen_string_literal: true

require_relative 'object'

module Epuber
  module DSL
    class TreeObject < Object
      # @param [TreeObject] parent
      #
      def initialize(parent = nil)
        super()

        @parent = parent
        @sub_items = []

        parent.sub_items << self unless parent.nil?
      end

      # @return nil
      #
      def freeze
        super
        @sub_items.freeze
      end

      # @return [self] reference to parent
      #
      attr_reader :parent

      # @return [Array<self>] child items
      #
      attr_reader :sub_items

      # @return [Array<self>] child items
      #
      def flat_sub_items
        all = []

        sub_items.each do |item|
          all << item
          all.concat(item.flat_sub_items)
        end

        all
      end

      # @return [Bool] receiver is root
      #
      def root?
        @parent.nil?
      end

      # @return nil
      #
      def validate
        super
        sub_items.each(&:validate)
      end

      class << self
        # @return [Self]
        #
        attr_accessor :current_parent_object
      end

      # @yield [child_item]
      # @yieldparam child_item [self] created child item
      #
      # @return [self]
      #
      def create_child_item(*args)
        child = self.class.new(*args)

        parent_object_before = self.class.current_parent_object

        child.parent = parent_object_before || self
        child.parent.sub_items << child

        self.class.current_parent_object = child
        yield child if block_given?


        self.class.current_parent_object = parent_object_before

        child
      end

      # @return nil
      #
      def create_child_items
        yield self if block_given?
      end


      protected

      attr_writer :parent, :sub_items
    end
  end
end
