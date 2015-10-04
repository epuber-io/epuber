# encoding: utf-8

require_relative '../../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_types/xhtml_file'


module Epuber
  class Compiler
    module FileTypes



      describe XHTMLFile do
        include FakeFS::SpecHelpers

        before do
          @book = Book.new

          @ctx = CompilationContext.new(@book, @book.default_target)
          @ctx.file_resolver = FileResolver.new('/', '/.build')
        end

        it 'handles ugly file with all xml bullshit lines' do
          source = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <head>
    <title/>
    <meta charset="utf-8"/>
  </head>
  <body id="Nastaveni-mysli_001-az-304-1">
    <div class="_idGenObjectStyleOverride-1">
      <p>Some bullshit content</p>
    </div>
  </body>
</html>
'
          File.write('some_file.xhtml', source)

          file = XHTMLFile.new('some_file.xhtml')
          file.destination_path = 'some_file_dest.xhtml'
          resolve_file_paths(file)

          file.process(@ctx)

          expect(File.read('some_file_dest.xhtml')).to eq source
        end

        it 'handles xml header on next line' do
          source = '
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <head>
    <title/>
    <meta charset="utf-8"/>
  </head>
  <body id="Nastaveni-mysli_001-az-304-1">
    <div class="_idGenObjectStyleOverride-1">
      <p>Some bullshit content</p>
    </div>
  </body>
</html>
'
          File.write('some_file.xhtml', source)

          file = XHTMLFile.new('some_file.xhtml')
          file.destination_path = 'some_file_dest.xhtml'
          resolve_file_paths(file)

          expect {
            file.process(@ctx)
          }.to output('XML header must be at the beginning of document
  (in file some_file.xhtml line 1'.ansi.yellow + "\n").to_stdout

          expect(File.read('some_file_dest.xhtml')).to eq source.lstrip # lstrip is to remove white characters at beginning
        end
      end



    end
  end
end
