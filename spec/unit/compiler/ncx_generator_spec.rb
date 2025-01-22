# frozen_string_literal: true

require_relative '../../spec_helper'


module Epuber
  class Compiler
    describe NcxGenerator do
      include FakeFS::SpecHelpers

      before do
        FileUtils.mkdir_p(%w[source dest])
        FileUtils.touch(%w[/source/txt1.xhtml /source/txt2.xhtml /source/txt3.xhtml /source/txt4.xhtml])

        book              = Book.new
        ctx               = Compiler::CompilationContext.new(book, book.all_targets.first)
        ctx.file_resolver = Compiler::FileResolver.new('/source', '/dest')
        @sut              = described_class.new(ctx)
      end

      it 'creates full metadata structure for default epub 2.0' do
        book = Book.new do |b|
          b.title        = 'Práce na dálku'
          b.author       = 'Jared Diamond'
          b.published    = '10. 12. 2014'
          b.publisher    = 'Jan Melvil Publishing'
          b.language     = 'cs'
          b.version      = 1.0
          b.is_ibooks    = true
          b.custom_fonts = true
          b.epub_version = 2.0

          b.toc do |toc, _target|
            toc.file 'txt1', 'Text 1'
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

        ncx = @sut.generate

        nav_points = ncx.css('ncx > navMap > navPoint')
        node = nav_points.shift
        expect(node.at_css('navLabel > text').inner_html).to eq 'Text 1'
        expect(node.at_css('content')['src']).to eq 'txt1.xhtml'

        node = nav_points.shift
        expect(node.at_css('navLabel > text').inner_html).to eq 'Text 2, awesome!'
        expect(node.at_css('content')['src']).to eq 'txt2.xhtml'

        node = nav_points.shift

        # epub 2 doesn't allow to use tags inside of <text>
        expect(node.at_css('navLabel > text').inner_html).to eq 'Text 3, <strong>COOL</strong>'
        expect(node.at_css('content')['src']).to eq 'txt3.xhtml'
      end
    end
  end
end
