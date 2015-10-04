# encoding: utf-8

require_relative '../../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_types/bade_file'


module Epuber
  class Compiler
    module FileTypes



      describe BadeFile do
        include FakeFS::SpecHelpers

        it 'handles ugly file with all xml bullshit lines' do
          source = 'import "dep.bade"

mixin bla()
  bla text

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
      +bla
    </div>
  </body>
</html>
'
          FileUtils.touch('dep.bade')
          File.write('some_file.bade', source)

          file = BadeFile.new('some_file.bade')
          file.destination_path = 'some_file.xhtml'
          resolve_file_paths(file)

          book = Book.new

          ctx = CompilationContext.new(book, book.default_target)
          ctx.file_resolver = FileResolver.new('/', '/.build')

          file.process(ctx)

          expect(File.read('some_file.xhtml')).to eq '<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <head>
    <title/>
    <meta charset="utf-8"/>
  </head>
  <body id="Nastaveni-mysli_001-az-304-1">
    <div class="_idGenObjectStyleOverride-1">
      <p>Some bullshit content</p>
      <bla>text</bla>
    </div>
  </body>
</html>
'
        end

      end



    end
  end
end
