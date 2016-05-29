# encoding: utf-8

require_relative '../../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_types/stylus_file'


module Epuber
  class Compiler
    module FileTypes



      describe StylusFile do
        include FakeFS::SpecHelpers

        let (:ctx) do
          book = Book.new

          ctx = CompilationContext.new(book, book.default_target)
          ctx.file_resolver = FileResolver.new('/', '/.build')

          ctx
        end

        it 'finds dependency files' do
          source = %q(
@import "abc.styl"
@import 'def.styl'
)
          FileUtils.mkdir_p('/abc')
          File.write('/abc/some_file.styl', source)
          FileUtils.touch('/abc/abc.styl')
          FileUtils.touch('/abc/def.styl')

          file = StylusFile.new('/abc/some_file.styl')
          file.destination_path = 'abc/some_file.css'
          file.compilation_context = ctx
          resolve_file_paths(file)

          expect(file.find_dependencies).to contain_exactly 'abc.styl', 'def.styl'
        end


      end



    end
  end
end
