# frozen_string_literal: true

require_relative '../../spec_helper'


module Epuber
  class Compiler
    describe NavGenerator do
      include FakeFS::SpecHelpers

      before do
        FileUtils.mkdir_p(%w[source dest])
        FileUtils.touch(%w[/source/txt1.xhtml /source/txt2.xhtml /source/txt3.xhtml /source/txt4.xhtml])

        book              = Book.new
        ctx               = Compiler::CompilationContext.new(book, book.all_targets.first)
        ctx.file_resolver = Compiler::FileResolver.new('/source', '/dest')
        @sut              = described_class.new(ctx)
      end

      it 'creates minimal xml structure for empty book' do
        opf_xml = @sut.generate
        expect(opf_xml).to have_xpath('/html/body')
      end

      it 'creates full metadata structure for default epub 3.0' do
        book = Book.new do |b|
          b.title        = 'Práce na dálku'
          b.author       = 'Jared Diamond'
          b.published    = '10. 12. 2014'
          b.publisher    = 'Jan Melvil Publishing'
          b.language     = 'cs'
          b.version      = 1.0
          b.is_ibooks    = true
          b.custom_fonts = true

          b.toc do |toc, _target|
            toc.file 'txt1', 'Text 1', :landmark_start_page
            toc.file 'txt2', 'Text 2, awesome!'
            toc.file 'txt3', 'Text 3, <strong>COOL</strong>'
          end
        end
        book.finish_toc

        ctx               = Compiler::CompilationContext.new(book, book.all_targets.first)
        resolver          = Compiler::FileResolver.new('/source', '/dest')
        book.default_target.root_toc.sub_items.each { |item| resolver.add_file_from_request(item.file_request) }
        ctx.file_resolver = resolver
        @sut              = described_class.new(ctx)

        nav_xml = @sut.generate
        expect(nav_xml).to have_xpath('/html/head/title', book.title)

        toc = nav_xml.at_css('html > body > nav[epub|type="toc"]')
        expect(toc.css('li > a').map { |a| a['href'] }).to contain_exactly 'txt1.xhtml', 'txt2.xhtml', 'txt3.xhtml'
        expect(toc.css('li > a').map(&:inner_html)).to contain_exactly 'Text 1', 'Text 2, awesome!',
                                                                       'Text 3, <strong>COOL</strong>'

        landmarks = nav_xml.at_css('html > body > nav[epub|type="landmarks"]')
        expect(landmarks.css('li > a').map do |a|
                 a['epub:type']
               end).to contain_exactly 'bodymatter', 'ibooks:reader-start-page'
        expect(landmarks.css('li > a').map { |a| a['href'] }).to contain_exactly 'txt1.xhtml', 'txt1.xhtml'
      end

      it 'does not create ol tag when there is no child' do
        book = Book.new do |b|
          b.title        = 'Práce na dálku'
          b.author       = 'Jared Diamond'
          b.published    = '10. 12. 2014'
          b.publisher    = 'Jan Melvil Publishing'
          b.language     = 'cs'
          b.version      = 1.0
          b.is_ibooks    = true
          b.custom_fonts = true

          b.toc do |toc, _target|
            toc.file 'txt1', 'Text 1', :landmark_start_page
            toc.file 'txt2', 'Text 2, awesome!' do
              toc.file 'txt3'
            end
          end
        end
        book.finish_toc

        ctx               = Compiler::CompilationContext.new(book, book.all_targets.first)
        resolver          = Compiler::FileResolver.new('/source', '/dest')
        book.default_target.root_toc.sub_items.each do |item|
          resolver.add_file_from_request(item.file_request)
          item.sub_items.each do |subitem|
            resolver.add_file_from_request(subitem.file_request)
          end
        end
        ctx.file_resolver = resolver
        @sut              = described_class.new(ctx)

        nav_xml = @sut.generate
        toc = nav_xml.at_css('html > body > nav[epub|type="toc"]')

        expect(toc.css('li > ul')).to be_empty
      end
    end
  end
end
