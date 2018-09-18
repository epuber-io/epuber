# encoding: utf-8

require 'claide/ansi'

require_relative '../../spec_helper'

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

        it 'can parse xml with headers' do
          input = <<-XML.strip_heredoc
            <?xml version="1.0" encoding="UTF-8" standalone="no"?>
            <!DOCTYPE html>
            <p>abc</p>
            <p>abc2</p>
            <p>abc3</p>
            <p>abc4</p>
            <p>abc5</p>
            <p>abc6</p>
            <p>abc7</p>
          XML

          doc = XHTMLProcessor.xml_document_from_string(input)

          expect(doc.root.name).to eq 'body'
          expect(doc.root.children.count).to eq 15 # 7 elements + 8 newlines

          expected_output = <<-XML.strip_heredoc
            <?xml version="1.0" encoding="UTF-8" standalone="no"?>
            <!DOCTYPE html>
            <body>
            <p>abc</p>
            <p>abc2</p>
            <p>abc3</p>
            <p>abc4</p>
            <p>abc5</p>
            <p>abc6</p>
            <p>abc7</p>
            </body>
          XML

          expect(doc.to_s).to eq expected_output
        end

        it 'can parse xml where is html root element missing' do
          input = <<~XML
            <?xml version="1.0" encoding="UTF-8" standalone="no"?>
            <!DOCTYPE html>

            <head>
              <script type="text/javascript" src="../scripts/resize.js" />
            </head>
            <body>
              <p>Some text here</p>
            </body>
          XML

          doc = XHTMLProcessor.xml_document_from_string(input)
          expect(doc.root.name).to eq 'html'

          expected_output = <<~XML
            <?xml version="1.0" encoding="UTF-8" standalone="no"?>
            <!DOCTYPE html>
            <html>
            <head>
              <script type="text/javascript" src="../scripts/resize.js"/>
            </head>
            <body>
              <p>Some text here</p>
            </body>
            </html>
          XML

          expect(doc.to_s).to eq expected_output
        end

        it 'can parse copyright from 4 hour working week book' do
          file_path = File.join(spec_root, 'fixtures/4HPT_copyright.xhtml')
          FakeFS::FileSystem.clone(file_path)
          input = File.read(file_path)

          expect {
            XHTMLProcessor.xml_document_from_string(input)
          }.to_not raise_error
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
          expect(doc.at_css('html head meta[@charset="utf-8"]')).to_not be_nil
          expect(doc.at_css('html body')).to_not be_nil
          expect(doc.at_css('html body p')).to_not be_nil
          expect(doc.css('html body p').map(&:to_s).join).to eq input_str
        end

        it 'adds all missing elements to empty <html/>' do
          input = '<html/>'
          doc = XHTMLProcessor.xml_document_from_string(input)
          XHTMLProcessor.add_missing_root_elements(doc, 'Baf', Epuber::Version.new(3.0))

          expected = <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <html>
              <head>
                <title>Baf</title>
                <meta charset="utf-8"/>
              </head>
              <body/>
            </html>
          XML

          expect(doc.to_s).to eq expected
        end
      end

      context '.add_styles' do
        it 'adds missing links to empty head' do
          doc = XHTMLProcessor.xml_document_from_string('')
          XHTMLProcessor.add_missing_root_elements(doc, 'Baf', Epuber::Version.new(3.0))

          expect(doc.css('link[rel="stylesheet"]').size).to eq 0

          XHTMLProcessor.add_styles(doc, ['abc', 'def'])

          expect(doc.css('link[rel="stylesheet"]').map {|node| node['href']}).to contain_exactly 'abc', 'def'
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

          expect(doc.css('link[rel="stylesheet"]').map {|node| node['href']}).to contain_exactly 'abc', 'def', 'qwe'
        end

        it 'will not add duplicated items' do
          doc = XHTMLProcessor.xml_document_from_string('')
          XHTMLProcessor.add_missing_root_elements(doc, 'Baf', Epuber::Version.new(3.0))

          XHTMLProcessor.add_styles(doc, ['abc', 'def'])
          XHTMLProcessor.add_styles(doc, ['abc', 'def'])
          XHTMLProcessor.add_styles(doc, ['abc', 'def'])
          XHTMLProcessor.add_styles(doc, ['abc', 'def'])

          expect(doc.css('link[rel="stylesheet"]').map {|node| node['href']}).to contain_exactly 'abc', 'def'
        end

        it 'will not add style that is already there' do
          input_str = '<html>
              <head>
                <link rel="stylesheet" type="text/css" href="qwe" />
              </head>
            </html>'
          doc = XHTMLProcessor.xml_document_from_string(input_str)
          XHTMLProcessor.add_missing_root_elements(doc, 'Baf', Epuber::Version.new(3.0))

          expect(doc.css('link[rel="stylesheet"]').size).to eq 1

          XHTMLProcessor.add_styles(doc, ['qwe'])

          expect(doc.css('link[rel="stylesheet"]').map {|node| node['href']}).to contain_exactly 'qwe'
        end
      end

      context '.add_scripts' do
        it 'adds missing scripts to empty head' do
          # Given
          doc = XHTMLProcessor.xml_document_from_string('')
          XHTMLProcessor.add_missing_root_elements(doc, 'Baf', Epuber::Version.new(3.0))

          expect(doc.css('script').size).to eq 0

          # When
          XHTMLProcessor.add_scripts(doc, %w(abc def))

          # Then
          expect(doc.css('script').map {|node| node['src']}).to contain_exactly 'abc', 'def'
        end

        it 'adds missing links to styles' do
          input_str = '<html>
              <head>
                <script type="text/javascript" src="qwe"></script>
              </head>
            </html>'
          doc = XHTMLProcessor.xml_document_from_string(input_str)
          XHTMLProcessor.add_missing_root_elements(doc, 'Baf', Epuber::Version.new(3.0))

          expect(doc.css('script').size).to eq 1

          XHTMLProcessor.add_scripts(doc, %w(abc def))

          expect(doc.css('script').map {|node| node['src']}).to contain_exactly 'abc', 'def', 'qwe'
        end

        it 'will not add duplicated items' do
          doc = XHTMLProcessor.xml_document_from_string('')
          XHTMLProcessor.add_missing_root_elements(doc, 'Baf', Epuber::Version.new(3.0))

          XHTMLProcessor.add_scripts(doc, %w(abc def))
          XHTMLProcessor.add_scripts(doc, %w(abc def))
          XHTMLProcessor.add_scripts(doc, %w(abc def))
          XHTMLProcessor.add_scripts(doc, %w(abc def))

          expect(doc.css('script').map {|node| node['src']}).to contain_exactly 'abc', 'def'
        end
      end

      context '.add_viewport' do
        it 'adds viewport when there is no other' do
          xml = '<p>aaa</p>'
          doc = XHTMLProcessor.xml_document_from_string(xml)
          XHTMLProcessor.add_missing_root_elements(doc, 'Bla', Epuber::Version.new(2.0))

          XHTMLProcessor.add_viewport(doc, Epuber::Size.new(100, 200))

          meta = doc.at_css('html > head > meta[name="viewport"]')
          expect(meta['content']).to eq 'width=100,height=200'
        end

        it "doesn't viewport when there is some already existing" do
          xml = '
          <html>
            <head>
              <meta name="viewport" content="width=50,height=300" />
            </head>
            <body>
              <p>aaa</p>
            </body>
          </html>'

          doc = XHTMLProcessor.xml_document_from_string(xml)
          XHTMLProcessor.add_missing_root_elements(doc, 'Bla', Epuber::Version.new(2.0))

          XHTMLProcessor.add_viewport(doc, Epuber::Size.new(100, 200))

          meta = doc.at_css('html > head > meta[name="viewport"]')
          expect(meta['content']).to eq 'width=50,height=300'
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

          url = XHTMLProcessor.resolved_link_to_file('http://www.gutenberg.org', nil, 'root.txt', finder)
          expect(url).to eq URI('http://www.gutenberg.org')
          expect(url.to_s).to eq 'http://www.gutenberg.org'
        end

        it 'is ok with relative id reference in file' do
          FileUtils.touch('root.txt')
          finder = FileFinders::Normal.new('/')

          url = XHTMLProcessor.resolved_link_to_file('#some_id', nil, 'root.txt', finder)
          expect(url).to eq URI('#some_id')
          expect(url.to_s).to eq '#some_id'

          url = XHTMLProcessor.resolved_link_to_file('#toc', nil, 'root.txt', finder)
          expect(url).to eq URI('#toc')
          expect(url.to_s).to eq '#toc'
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

        it 'will not raise for valid path' do
          FileUtils.mkdir_p('image')
          FileUtils.touch('image/stan_mindsetbw.png')

          FileUtils.mkdir_p('text')
          FileUtils.touch('text/root.txt')

          finder = FileFinders::Normal.new('/')

          expect {
            XHTMLProcessor.resolved_link_to_file('image/stan_mindsetbw.png', nil, 'text/root.txt', finder)
          }.to_not raise_error
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
          expect(links).to contain_exactly URI('ref1.xhtml'), URI('ref2.txt#abc'), URI('abc/ref10.xhtml')
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

      context '.resolve_links' do
        before do
          FileUtils.mkdir_p('folder')
          FileUtils.touch(%w(root.xhtml ref1.xhtml ref2.xhtml folder/ref10.xhtml))
          FileUtils.touch(%w(image1.jpeg image2.jpg folder/image3.png))

          @finder = FileFinders::Normal.new('/')
        end

        it 'resolves links in <a>' do
          doc = XHTMLProcessor.xml_document_from_string('<div><a href="ref1" /><a href="ref2.xhtml#abc"/><a href="ref10" /></div>')

          links = XHTMLProcessor.resolve_links(doc, 'root.xhtml', @finder)

          expect(doc.root.to_xml(indent: 0, save_with: 0)).to eq '<div><a href="ref1.xhtml"/><a href="ref2.xhtml#abc"/><a href="folder/ref10.xhtml"/></div>'
          expect(links).to contain_exactly URI('ref1.xhtml'), URI('ref2.xhtml#abc'), URI('folder/ref10.xhtml')
        end

        it 'resolves links in <map>' do
          source = '<map><area href="ref1" /><area href="ref2.xhtml#abc"/><area href="ref10" /></map>'
          doc = XHTMLProcessor.xml_document_from_string(source)

          links = XHTMLProcessor.resolve_links(doc, 'root.xhtml', @finder)

          expect(doc.root.to_xml(indent: 0, save_with: 0)).to eq '<map><area href="ref1.xhtml"/><area href="ref2.xhtml#abc"/><area href="folder/ref10.xhtml"/></map>'
          expect(links).to contain_exactly URI('ref1.xhtml'), URI('ref2.xhtml#abc'), URI('folder/ref10.xhtml')
        end
      end

      it 'detects whether xhtml document is using some scripts' do
        doc = XHTMLProcessor.xml_document_from_string('<script>var baf = document.shit();</script>')
        expect(XHTMLProcessor.using_javascript?(doc)).to be_truthy

        doc = XHTMLProcessor.xml_document_from_string('<script src="baf.js" />')
        expect(XHTMLProcessor.using_javascript?(doc)).to be_truthy

        doc = XHTMLProcessor.xml_document_from_string('<p>some text</p>')
        expect(XHTMLProcessor.using_javascript?(doc)).to be_falsey
      end

      context '.resolve_images' do
        it 'resolves not existing file in destination' do
          FileUtils.mkdir_p('/images')
          FileUtils.touch(%w(/images/image1.png /images/image2.jpg /file.xhtml))

          xml = '<div><img src="image1" /></div>'
          doc = XHTMLProcessor.xml_document_from_string(xml)
          resolver = FileResolver.new('/', '/.build')

          expect(resolver.files.count).to eq 0

          XHTMLProcessor.resolve_images(doc, 'file.xhtml', resolver)

          expect(doc.at_css('img')['src']).to eq 'images/image1.png'
          expect(resolver.files.count).to eq 1
        end

        it 'resolves existing file in destination' do
          FileUtils.mkdir_p('/images')
          FileUtils.touch(%w(/images/image1.png /images/image2.jpg /file.xhtml))

          resolver = FileResolver.new('/', '/.build')
          resolver.add_file_from_request(Book::FileRequest.new('image1.png', false))

          expect(resolver.files.count).to eq 1


          xml = '<div><img src="image1" /></div>'
          doc = XHTMLProcessor.xml_document_from_string(xml)


          XHTMLProcessor.resolve_images(doc, 'file.xhtml', resolver)

          expect(doc.at_css('img')['src']).to eq 'images/image1.png'
          expect(resolver.files.count).to eq 1
        end
      end

      context '.resolve_scripts' do
        it 'resolves not existing files in destination' do
          FileUtils.mkdir_p('/scripts')
          FileUtils.touch(%w(/scripts/script.js /scripts/script2.coffee /file.xhtml))

          xml = <<-XML
            <html>
              <head>
                <script src="script"></script>
              </head>
              <body>
                <script src="script2"></script>
              </body>
            </html>
          XML

          doc = XHTMLProcessor.xml_document_from_string(xml)
          resolver = FileResolver.new('/', '/.build')

          expect(resolver.files.count).to eq 0

          XHTMLProcessor.resolve_scripts(doc, 'file.xhtml', resolver)

          expect(doc.at_css('head script')['src']).to eq 'scripts/script.js'
          expect(doc.at_css('body script')['src']).to eq 'scripts/script2.js'
          expect(resolver.files.count).to eq 2
        end

        it 'resolves existing file in destination' do
          # Given
          FileUtils.mkdir_p('/scripts')
          FileUtils.touch(%w(/scripts/script.js /scripts/script2.coffee /file.xhtml))

          resolver = FileResolver.new('/', '/.build')
          resolver.add_file_from_request(Book::FileRequest.new('script2', false))

          expect(resolver.files.count).to eq 1


          xml = <<-XML
            <html>
              <head>
                <script src="script"></script>
              </head>
              <body>
                <script src="script2"></script>
              </body>
            </html>
          XML
          doc = XHTMLProcessor.xml_document_from_string(xml)

          # When
          XHTMLProcessor.resolve_scripts(doc, 'file.xhtml', resolver)

          # Then
          expect(doc.at_css('head script')['src']).to eq 'scripts/script.js'
          expect(doc.at_css('body script')['src']).to eq 'scripts/script2.js'
          expect(resolver.files.count).to eq 2
        end
      end

      context '.resolve_stylesheets' do
        it 'resolves not existing files in destination' do
          FileUtils.mkdir_p('/styles')
          FileUtils.touch(%w(/styles/style1.css /styles/style2.styl /file.xhtml))

          xml = <<-XML
            <html>
              <head>
                <link rel="stylesheet" href="style1">
              </head>
              <body>
                <link rel="stylesheet" href="style2">
              </body>
            </html>
          XML

          doc = XHTMLProcessor.xml_document_from_string(xml)
          resolver = FileResolver.new('/', '/.build')

          expect(resolver.files.count).to eq 0

          XHTMLProcessor.resolve_stylesheets(doc, 'file.xhtml', resolver)

          expect(doc.at_css('head link')['href']).to eq 'styles/style1.css'
          expect(doc.at_css('body link')['href']).to eq 'styles/style2.css'
          expect(resolver.files.count).to eq 2
        end

        it 'resolves existing file in destination' do
          # Given
          FileUtils.mkdir_p('/styles')
          FileUtils.touch(%w(/styles/style1.css /styles/style2.styl /file.xhtml))

          xml = <<-XML
            <html>
              <head>
                <link rel="stylesheet" href="style1">
              </head>
              <body>
                <link rel="stylesheet" href="style2">
              </body>
            </html>
          XML

          doc = XHTMLProcessor.xml_document_from_string(xml)

          resolver = FileResolver.new('/', '/.build')
          resolver.add_file_from_request(Book::FileRequest.new('style1', false))

          expect(resolver.files.count).to eq 1

          # When
          XHTMLProcessor.resolve_stylesheets(doc, 'file.xhtml', resolver)

          # Then
          expect(doc.at_css('head link')['href']).to eq 'styles/style1.css'
          expect(doc.at_css('body link')['href']).to eq 'styles/style2.css'
          expect(resolver.files.count).to eq 2
        end
      end

      context 'using_remote_resources?' do
        it 'detects using remote images' do
          doc = XHTMLProcessor.xml_document_from_string('<img src="http://lorempixel.com/400/200" />')
          expect(XHTMLProcessor.using_remote_resources?(doc)).to be_truthy
        end

        it "not detects remote resources when there aren't any remote images" do
          doc = XHTMLProcessor.xml_document_from_string('<img src="images/cover_image.jpg" />')
          expect(XHTMLProcessor.using_remote_resources?(doc)).to be_falsey
        end

        it 'detects using remote styles' do
          doc = XHTMLProcessor.xml_document_from_string('<link rel="stylesheet" type="text/css" href="http://httpbin.org/style.css">')
          expect(XHTMLProcessor.using_remote_resources?(doc)).to be_truthy
        end

        it "not detects remote resources when there aren't any remote styles" do
          doc = XHTMLProcessor.xml_document_from_string('<link rel="stylesheet" type="text/css" href="style.css">')
          expect(XHTMLProcessor.using_remote_resources?(doc)).to be_falsey
        end

        it 'detects using remote scripts' do
          doc = XHTMLProcessor.xml_document_from_string('<script src="http://httpbin.orgtutorial/browser/script/rabbits.js"></script>')
          expect(XHTMLProcessor.using_remote_resources?(doc)).to be_truthy
        end

        it "not detects remote resources when there aren't any remote scripts" do
          doc = XHTMLProcessor.xml_document_from_string('<script src="../browser/script/rabbits.js"></script>')
          expect(XHTMLProcessor.using_remote_resources?(doc)).to be_falsey
        end
      end
    end


  end
end
