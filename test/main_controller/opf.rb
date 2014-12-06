require_relative '../matchers/xml'

require_relative '../../lib/epuber/main_controller'
require_relative '../../lib/epuber/book'

module Epuber
  describe MainController do

    describe 'MainController#generate_opf' do
      before do
        @sut = MainController.new

        @sut.book = Book.new do |book|
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
        @sut.book = Book.new

        opf_xml = @sut.generate_opf
        expect(opf_xml).to have_xpath('/package/@version', '3.0')
        expect(opf_xml).to have_xpath('/package/@unique-identifier', MainController::OPF_UNIQUE_ID)
        expect(opf_xml).to have_xpath('/package/metadata')
        expect(opf_xml).to have_xpath('/package/manifest')
        expect(opf_xml).to have_xpath('/package/spine')
      end

      it 'creates full metadata structure' do
        @sut.book = Book.new do |book|
          book.title = 'Práce na dálku'
        end

        expect(@sut.generate_opf).to have_xpath('/package/metadata/dc:title', 'Práce na dálku')
      end
    end


  end
end
