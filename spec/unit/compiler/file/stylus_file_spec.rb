# frozen_string_literal: true

require_relative '../../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_types/stylus_file'


module Epuber
  class Compiler
    module FileTypes
      describe StylusFile do
        describe 'FakeFS parts' do
          include FakeFS::SpecHelpers

          let(:ctx) do
            book = Book.new

            ctx = CompilationContext.new(book, book.default_target)
            ctx.file_resolver = FileResolver.new('/', '/.build')

            ctx
          end

          it 'finds dependency files' do
            source = <<~STYLUS
              @import "abc.styl"
              @import 'def.styl'
            STYLUS

            FileUtils.mkdir_p('/abc')
            File.write('/abc/some_file.styl', source)
            FileUtils.touch('/abc/abc.styl')
            FileUtils.touch('/abc/def.styl')

            file = described_class.new('/abc/some_file.styl')
            file.destination_path = 'abc/some_file.css'
            file.compilation_context = ctx
            resolve_file_paths(file)

            expect(file.find_dependencies).to contain_exactly 'abc.styl', 'def.styl'
          end
        end



        describe 'Real' do
          FileUtils.mkdir_p('/tmp/epuber_stylus_tests')

          let(:ctx) do
            book = Book.new

            ctx = CompilationContext.new(book, book.default_target)
            ctx.file_resolver = FileResolver.new('/tmp/epuber_stylus_tests', '/tmp/epuber_stylus_tests/.build')

            ctx
          end

          it 'allows to use constants inside stylus files' do
            source = <<~STYLUS
              __abc = {
                 hej: "hou"
              }

              a
                // value: __const.some_value
                value: __abc.hej
                value2: __const.some_value

            STYLUS

            File.write('/tmp/epuber_stylus_tests/some_file.styl', source)

            file = described_class.new('/tmp/epuber_stylus_tests/some_file.styl')
            file.destination_path = '/tmp/epuber_stylus_tests/some_file.css'
            file.compilation_context = ctx
            resolve_file_paths(file)

            ctx.book.default_target.add_const 'some_value' => 'abc'

            file.process(ctx)

            expected = <<~CSS
              a {
                value: "hou";
                value2: 'abc';
              }
            CSS

            expect(File.read(file.final_destination_path)).to eq expected
          end
        end
      end
    end
  end
end
