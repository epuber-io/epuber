require 'nokogiri'
require 'rspec'

RSpec::Matchers.define :have_xpath do |xpath, text|
  match do |body|
    doc = Nokogiri::XML::Document.parse(body)

    # HACK for dealing with namespaces
    # implicit namespace
    xpath = xpath.split('/').map { |node|
      if node.length == 0 || node.start_with?('@') || node.include?(':')
        node
      else
        "xmlns:#{node}"
      end
    }.join('/')

    nodes = doc.xpath(xpath)

    expect(nodes.empty?).to be_falsey

    if text
      nodes.each do |node|
        expect(node.content).to eq text
      end
    end

    true
  end

  failure_message do |body|
    "expected to find xml tag #{xpath} in:\n#{body}"
  end

  failure_message_when_negated do |response|
    "expected not to find xml tag #{xpath} in:\n#{body}"
  end

  description do
    "have xml tag #{xpath}"
  end
end
