# encoding: utf-8

require_relative '../helpers/spec_helper'

require_relative '../matchers/xml'

require_relative '../../lib/epuber/compiler'
require_relative '../../lib/epuber/book/target'
require_relative '../../lib/epuber/book'

module Epuber
  describe Compiler::OPFGenerator do
    before do
      book = Book.new
      @sut = Compiler::OPFGenerator.new(book, book.targets.first, Compiler::FileResolver.new('', ''))
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
        ### b.cover_image = 'cover.jpg'
      end

      @sut = Compiler::OPFGenerator.new(book, book.targets.first, Compiler::FileResolver.new('', ''))

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

        ### expect(metadata).to have_xpath("/meta[@property='cover']", 'cover.jpg')
      end

      with_xpath(opf_xml, '/package/manifest') do |_manifest|
        ### expect(manifest).to have_xpath("/item[@properties='cover-image']")
      end
    end
  end
end
