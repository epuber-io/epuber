# encoding: utf-8

require_relative '../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/xhtml_processor'


module Epuber
  class Compiler


    describe XHTMLProcessor do
      include FakeFS::SpecHelpers

      context '.xml_document_from_string' do
        it 'can parse simple xml document' do
          input_str = '<p>abc</p>'

          doc = XHTMLProcessor.xml_document_from_string(input_str)

          expect(doc.root.name).to eq 'p'
          expect(doc.to_s).to eq %{<?xml version="1.0" encoding="UTF-8"?>\n<p>abc</p>\n}
          expect(doc.root.to_s).to eq input_str
        end

        it 'can parse simple xml without root element' do
          input_str = %q{<p>abc</p><p>abc</p>}

          doc = XHTMLProcessor.xml_document_from_string(input_str)

          expect(doc.root.name).to eq 'body'
          expect(doc.root.children.count).to eq 2
        end
      end
    end


  end
end
