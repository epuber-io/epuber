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

      context '.add_missing_root_elements' do
        it 'adds all missing elements' do
          input_str = '<p>abc</p><p>abcd</p>'
          doc = XHTMLProcessor.xml_document_from_string(input_str)

          expect(doc.at_css('p')).to_not be_nil

          # all items are missing
          expect(doc.at_css('html')).to be_nil
          expect(doc.at_css('html head')).to be_nil
          expect(doc.at_css('html head title')).to be_nil
          expect(doc.at_css('html body')).to be_nil
          expect(doc.at_css('html body p')).to be_nil

          XHTMLProcessor.add_missing_root_elements(doc, 'Baf', Epuber::Version.new(3.0))

          # and they are there
          expect(doc.at_css('html')).to_not be_nil
          expect(doc.at_css('html').namespaces).to include 'xmlns' => 'http://www.w3.org/1999/xhtml'
          expect(doc.at_css('html').namespaces).to include 'xmlns:epub' => 'http://www.idpf.org/2007/ops'
          expect(doc.at_css('html head')).to_not be_nil
          expect(doc.at_css('html head title')).to_not be_nil
          expect(doc.at_css('html head title').to_s).to eq '<title>Baf</title>'
          expect(doc.at_css('html body')).to_not be_nil
          expect(doc.at_css('html body p')).to_not be_nil
          expect(doc.css('html body p').map(&:to_s).join).to eq input_str
        end
      end

      context '.add_style_links' do
        it 'adds missing links to empty head' do
          doc = XHTMLProcessor.xml_document_from_string('')
          XHTMLProcessor.add_missing_root_elements(doc, 'Baf', Epuber::Version.new(3.0))

          expect(doc.css('link[rel="stylesheet"]').size).to eq 0

          XHTMLProcessor.add_styles(doc, ['abc', 'def'])

          expect(doc.css('link[rel="stylesheet"]').size).to eq 2
          expect(doc.css('link[rel="stylesheet"]').map {|node| node['href']}).to include 'abc', 'def'
        end

        it 'adds missing links to styles' do
          input_str = '<html>
              <head>
                <link rel="stylesheet" type="text/css" href="qwe" />
              </head>
            </html>'
          doc = XHTMLProcessor.xml_document_from_string(input_str)
          XHTMLProcessor.add_missing_root_elements(doc, 'Baf', Epuber::Version.new(3.0))

          expect(doc.css('link[rel="stylesheet"]').size).to eq 1

          XHTMLProcessor.add_styles(doc, ['abc', 'def'])

          expect(doc.css('link[rel="stylesheet"]').size).to eq 3
          expect(doc.css('link[rel="stylesheet"]').map {|node| node['href']}).to include 'abc', 'def', 'qwe'
        end

        it 'will not add duplicated items' do
          doc = XHTMLProcessor.xml_document_from_string('')
          XHTMLProcessor.add_missing_root_elements(doc, 'Baf', Epuber::Version.new(3.0))

          XHTMLProcessor.add_styles(doc, ['abc', 'def'])
          XHTMLProcessor.add_styles(doc, ['abc', 'def'])
          XHTMLProcessor.add_styles(doc, ['abc', 'def'])
          XHTMLProcessor.add_styles(doc, ['abc', 'def'])

          expect(doc.css('link[rel="stylesheet"]').size).to eq 2
          expect(doc.css('link[rel="stylesheet"]').map {|node| node['href']}).to include 'abc', 'def'
        end
      end
    end


  end
end
