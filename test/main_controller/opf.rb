require_relative '../matchers/xml'

require_relative '../../lib/epuber/main_controller'
require_relative '../../lib/epuber/book'

module Epuber
  describe MainController do

    describe 'MainController#generate_opf' do
      before do
        @sut = MainController.new

        @sut.book = Book::Book.new do |book|
          book.title    = 'Práce na dálku'
          book.subtitle = 'Abc'

          book.author = {
            :first_name => 'Abc',
            :last_name  => 'def'
          }

          book.publisher = 'AAABBB'
          book.language = 'cs'
          book.isbn = '978-80-87270-98-2'
          book.print_isbn = '978-80-87270-98-0'
        end
      end

      it 'creates minimal xml structure for empty book' do
        @sut.book = Book::Book.new

        opf_xml = @sut.generate_opf
        expect(opf_xml).to have_xpath('/package/@version', '3.0') # is default
        expect(opf_xml).to have_xpath('/package/@unique-identifier', MainController::OPF_UNIQUE_ID)
        expect(opf_xml).to have_xpath('/package/metadata')
        expect(opf_xml).to have_xpath('/package/manifest')
        expect(opf_xml).to have_xpath('/package/spine')
      end

      it 'creates full metadata structure for default epub 3.0' do
        @sut.book = Book::Book.new do |book|
          book.title = 'Práce na dálku'
          book.author = {
            first_name: 'Jared',
            last_name: 'Diamond',
          }
          book.published = '10. 12. 2014'
          book.publisher = 'Jan Melvil Publishing'
          book.language = 'cs'
          book.version = 1.0
          book.is_ibooks = true
          book.custom_fonts = true
        end

        with_xpath(@sut.generate_opf, '/package/metadata') do |metadata|
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
        end
      end
    end
  end
end
