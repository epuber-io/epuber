# frozen_string_literal: true

require_relative '../../spec_helper'


module Epuber
  describe Compiler::OPFGenerator do
    include FakeFS::SpecHelpers

    before do
      book = Book.new
      ctx = Compiler::CompilationContext.new(book, book.all_targets.first)
      ctx.file_resolver = Compiler::FileResolver.new('/source', '/dest')
      ctx.file_resolver.add_file(Compiler::FileTypes::NcxFile.new)
      @sut = described_class.new(ctx)
    end

    it 'creates minimal xml structure for empty book' do
      opf_xml = @sut.generate_opf
      expect(opf_xml).to have_xpath('/package/@version', '3.0') # is default
      expect(opf_xml).to have_xpath('/package/@unique-identifier', Compiler::OPFGenerator::OPF_UNIQUE_ID)
      expect(opf_xml).to have_xpath('/package/metadata')
      expect(opf_xml).to have_xpath('/package/manifest')
      expect(opf_xml).to have_xpath('/package/spine')
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
        b.cover_image = 'cover.jpg'
      end

      FileUtils.mkdir_p('/source')
      FileUtils.touch('/source/cover.jpg')

      ctx = Compiler::CompilationContext.new(book, book.all_targets.first)
      ctx.file_resolver = Compiler::FileResolver.new('/source', '/dest')
      ctx.file_resolver.add_file_from_request(book.cover_image)
      ctx.file_resolver.add_file(Compiler::FileTypes::NcxFile.new)
      ctx.file_resolver.add_file(Compiler::FileTypes::NavFile.new)

      @sut = described_class.new(ctx)

      opf_xml = @sut.generate_opf
      with_xpath(opf_xml, '/package/metadata') do |metadata|
        expect(metadata).to have_xpath('/dc:title', 'Práce na dálku')
        expect(metadata).to have_xpath("/meta[@property='title-type']", 'main')

        expect(metadata).to have_xpath('/dc:creator', 'Jared Diamond')
        expect(metadata).to have_xpath("/meta[@property='file-as']", 'DIAMOND, Jared')
        expect(metadata).to have_xpath("/meta[@property='role']", 'aut')

        expect(metadata).to have_xpath('/dc:publisher', 'Jan Melvil Publishing')
        expect(metadata).to have_xpath('/dc:language', 'cs')
        expect(metadata).to have_xpath('/dc:date', '2014-12-10')

        expect(metadata).to have_xpath("/meta[@property='dcterms:modified']", Time.now.utc.iso8601)

        expect(metadata).to have_xpath("/meta[@property='ibooks:version']", '1.0')
        expect(metadata).to have_xpath("/meta[@property='ibooks:specified-fonts']", 'true')

        expect(metadata).to have_xpath("/meta[@name='cover']/@content", 'cover.jpg')
      end

      with_xpath(opf_xml, '/package/manifest') do |manifest|
        expect(manifest).to have_xpath("/item[@properties='cover-image']/@id", 'cover.jpg')
      end
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
        b.cover_image = 'cover.jpg'
      end

      FileUtils.mkdir_p('/source')
      FileUtils.touch('/source/cover.jpg')

      resolver = Compiler::FileResolver.new('/source', '/dest')

      resolver.add_file(Compiler::FileTypes::NcxFile.new)
      resolver.add_file_from_request(book.cover_image)

      ctx = Compiler::CompilationContext.new(book, book.all_targets.first)
      ctx.file_resolver = resolver
      @sut = described_class.new(ctx)

      opf_xml = @sut.generate_opf
      with_xpath(opf_xml, '/package/metadata') do |metadata|
        expect(metadata).to have_xpath('/dc:title', 'Práce na dálku')

        expect(metadata).to have_xpath('/dc:creator', 'Jared Diamond')
        expect(metadata).to have_xpath('/dc:creator/@opf:file-as', 'DIAMOND, Jared')
        expect(metadata).to have_xpath('/dc:creator/@opf:role', 'aut')

        expect(metadata).to have_xpath('/dc:publisher', 'Jan Melvil Publishing')
        expect(metadata).to have_xpath('/dc:language', 'cs')
        expect(metadata).to have_xpath('/dc:date', '2014-12-10')
      end
    end

    describe '.create_id_from_path' do
      it 'generates id without numbers at start' do
        def create_id(path)
          # `create_id_from_path` method is private, using this hack we can call the private method
          @sut.send(:create_id_from_path, path)
        end

        expect(create_id('4HSK/text/copyright.xhtml')).to eq 'HSK.text.copyright.xhtml'
      end
    end

    describe '.mime_type_for' do
      def mimetype(path)
        @sut.send(:mime_type_for, path)
      end

      it 'picks correct mimetype for .ttf files' do
        expect(mimetype('some-font.ttf')).to eq 'application/vnd.ms-opentype'
      end

      it 'picks correct mimetype for .jpg files' do
        expect(mimetype('some-image.jpg')).to eq 'image/jpeg'
      end
    end
  end
end
