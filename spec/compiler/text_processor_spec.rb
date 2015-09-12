# encoding: utf-8

require 'claide/ansi'

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

      context '.resolved_link_to_file' do
        it 'resolves links to other files in project' do
          FileUtils.mkdir_p('some/path')
          FileUtils.touch('some/path/origin.txt')
          FileUtils.touch('some/path/near.txt')
          FileUtils.touch('root.txt')

          finder = FileFinders::Normal.new('/')

          path = XHTMLProcessor.resolved_link_to_file('root', nil, 'some/path/origin.txt', finder)
          expect(path).to eq URI('../../root.txt')
          expect(path.to_s).to eq '../../root.txt'

          path = XHTMLProcessor.resolved_link_to_file('root.txt', nil, 'some/path/origin.txt', finder)
          expect(path).to eq URI('../../root.txt')
          expect(path.to_s).to eq '../../root.txt'

          path = XHTMLProcessor.resolved_link_to_file('../../root.txt', nil, 'some/path/origin.txt', finder)
          expect(path).to eq URI('../../root.txt')
          expect(path.to_s).to eq '../../root.txt'

          path = XHTMLProcessor.resolved_link_to_file('near.txt', nil, 'some/path/origin.txt', finder)
          expect(path).to eq URI('near.txt')
          expect(path.to_s).to eq 'near.txt'

          path = XHTMLProcessor.resolved_link_to_file('near', nil, 'some/path/origin.txt', finder)
          expect(path).to eq URI('near.txt')
          expect(path.to_s).to eq 'near.txt'
        end

        it 'is ok with remote urls, which have scheme' do
          FileUtils.touch('root.txt')
          finder = FileFinders::Normal.new('/')

          url = XHTMLProcessor.resolved_link_to_file('http://www.google.com', nil, 'root.txt', finder)
          expect(url).to eq URI('http://www.google.com')
          expect(url.to_s).to eq 'http://www.google.com'

          # https is ok
          url = XHTMLProcessor.resolved_link_to_file('https://www.google.com', nil, 'root.txt', finder)
          expect(url).to eq URI('https://www.google.com')
          expect(url.to_s).to eq 'https://www.google.com'

          url = XHTMLProcessor.resolved_link_to_file('https://google.com', nil, 'root.txt', finder)
          expect(url).to eq URI('https://google.com')
          expect(url.to_s).to eq 'https://google.com'
        end

        it 'is ok with relative id reference in file' do
          FileUtils.touch('root.txt')
          finder = FileFinders::Normal.new('/')

          url = XHTMLProcessor.resolved_link_to_file('#some_id', nil, 'root.txt', finder)
          expect(url).to eq URI('#some_id')
          expect(url.to_s).to eq '#some_id'
        end

        it 'is ok with relative id reference to another file' do
          FileUtils.touch('root.txt')
          FileUtils.touch('ref.txt')
          finder = FileFinders::Normal.new('/')

          url = XHTMLProcessor.resolved_link_to_file('ref#some_id', nil, 'root.txt', finder)
          expect(url).to eq URI('ref.txt#some_id')
          expect(url.to_s).to eq 'ref.txt#some_id'
        end

        it 'raise error when the file could not be found' do
          FileUtils.touch('root.txt')

          finder = FileFinders::Normal.new('/')

          expect {
            XHTMLProcessor.resolved_link_to_file('some_not_existing_file', nil, 'root.txt', finder)
          }.to raise_error FileFinders::FileNotFoundError
        end

        it 'raise error when the path is empty' do
          FileUtils.touch('root.txt')

          finder = FileFinders::Normal.new('/')

          expect {
            XHTMLProcessor.resolved_link_to_file('', nil, 'root.txt', finder)
          }.to raise_error FileFinders::FileNotFoundError
        end
      end

      context '.resolve_links_for' do
        it 'resolves links to files from tags with specific arguments' do
          FileUtils.mkdir_p('abc')
          FileUtils.touch(['root.txt', 'ref1.xhtml', 'ref2.txt', 'abc/ref10.xhtml'])

          finder = FileFinders::Normal.new('/')

          doc = XHTMLProcessor.xml_document_from_string('<div><a href="ref1" /><a href="ref2.txt#abc"/><a href="ref10" /></div>')

          links = XHTMLProcessor.resolve_links_for(doc, 'a', 'href', nil, 'root.txt', finder)

          expect(doc.root.to_xml(indent: 0, save_with: 0)).to eq '<div><a href="ref1.xhtml"/><a href="ref2.txt#abc"/><a href="abc/ref10.xhtml"/></div>'
          expect(links).to include URI('ref1.xhtml'), URI('ref2.txt#abc'), URI('abc/ref10.xhtml')
        end

        it 'prints warning when the attribute is empty' do
          FileUtils.touch('root.txt')
          finder = FileFinders::Normal.new('/')
          doc = XHTMLProcessor.xml_document_from_string('<a href=""/>', 'root.txt')

          expect {
            XHTMLProcessor.resolve_links_for(doc, 'a', 'href', nil, 'root.txt', finder)
          }.to output('Not found file matching pattern `` from context path root.txt.
  (in file root.txt line 1'.ansi.yellow + "\n").to_stdout
        end

        it "prints warning when the desired file can't be found" do
          FileUtils.touch('root.txt')
          finder = FileFinders::Normal.new('/')
          doc = XHTMLProcessor.xml_document_from_string('<a href="blabla"/>', 'root.txt')

          expect {
            XHTMLProcessor.resolve_links_for(doc, 'a', 'href', nil, 'root.txt', finder)
          }.to output('Not found file matching pattern `blabla` from context path root.txt.
  (in file root.txt line 1'.ansi.yellow + "\n").to_stdout
        end

        it 'silently skips tags without specified attributes' do
          FileUtils.touch('root.txt')
          finder = FileFinders::Normal.new('/')
          doc = XHTMLProcessor.xml_document_from_string('<a/>')

          expect {
            XHTMLProcessor.resolve_links_for(doc, 'a', 'href', nil, 'root.txt', finder)
          }.to_not output.to_stdout
        end
      end
    end


  end
end
