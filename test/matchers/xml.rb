# encoding: utf-8

require 'nokogiri'

require_relative '../spec_helper'

# @param xpath [String]
# @return [String]
#
def xpath_namespace_hack(xpath)
  # HACK: for dealing with namespaces
  # implicit namespace
  xpath.split('/').map do |node|
    nodename = node.gsub(/^([A-Za-z0-9_:]+).*/, '\1')
    if nodename.length == 0 || nodename.start_with?('@') || nodename.include?(':')
      node
    else
      "xmlns:#{node}"
    end
  end.join('/')
end

$global_xpath = nil

# @param doc [Nokogiri::XML::Document]
# @param xpath [String]
#
def with_xpath(doc, xpath, &block)
  xpath = xpath_namespace_hack(xpath)

  $global_xpath = xpath

  block.call(doc)

  $global_xpath = nil
end

RSpec::Matchers.define :have_xpath do |xpath, text|
  def test_with_message(message, &block)
    @possible_error_message = message
    block.call
    @possible_error_message = nil
  end

  match do |body|
    @original_xpath = xpath

    xpath = xpath_namespace_hack(xpath)
    xpath = $global_xpath + xpath unless $global_xpath.nil?


    doc = if body.is_a? Nokogiri::XML::Document
            body
          else
            Nokogiri::XML::Document.parse(body)
          end

    nodes = doc.xpath(xpath)


    test_with_message "not found any nodes for xpath #{@original_xpath}" do
      expect(nodes.empty?).to be_falsey
    end

    if text
      nodes.each do |node|
        message = "founded value '#{node.content}' doesn't match required value '#{text}' at xpath #{@original_xpath}"
        test_with_message message do
          expect(node.content).to eq text
        end
      end
    end

    true
  end

  failure_message do |body|
    if @possible_error_message.nil?
      "expected to find xml tag #{@original_xpath} in:\n#{body}"
    else
      "#{@possible_error_message} in:\n#{body}"
    end
  end

  failure_message_when_negated do |body|
    if @possible_error_message.nil?
      "expected not to find xml tag #{@original_xpath} in:\n#{body}"
    else
      "#{@possible_error_message} in:\n#{body}"
    end
  end

  description do
    "have xml tag #{@original_xpath}"
  end
end
