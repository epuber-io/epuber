# encoding: utf-8

require 'nokogiri'


class Nokogiri::XML::Node
  # @param [String] name
  # @param [Hash, String] args
  #
  # @return [Nokogiri::XML::Node] new parent node
  #
  def surround_with_element(name, *args, &block)
    new_parent = document.create_element(name, *args, &block)
    old_parent = parent

    self.parent = new_parent

    if old_parent.is_a?(Nokogiri::XML::Document)
      old_parent.root = new_parent
    else
      old_parent.children = new_parent
    end

    new_parent
  end
end
