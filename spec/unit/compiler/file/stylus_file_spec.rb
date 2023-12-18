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
          include_context 'with temp dir'

          let(:ctx) do
            book = Book.new

            ctx = CompilationContext.new(book, book.default_target)
            ctx.file_resolver = FileResolver.new(temp_dir, File.join(temp_dir, '.build'))

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

            File.write(File.join(temp_dir, 'some_file.styl'), source)

            file = described_class.new(File.join(temp_dir, 'some_file.styl'))
            file.destination_path = File.join(temp_dir, 'some_file.css')
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

          it 'modifies linked files using url()' do
            source = <<~STYLUS
              div
                background: url(image.png);
              div
                background: url("image");
            STYLUS

            FileUtils.mkdir_p(File.join(temp_dir, 'styles'))
            File.write(File.join(temp_dir, 'styles/some_file.styl'), source)
            FileUtils.mkdir_p(File.join(temp_dir, 'images'))
            FileUtils.touch(File.join(temp_dir, 'images/image.png'))

            file = described_class.new('styles/some_file.styl')
            file.destination_path = 'styles/some_file_res.css'
            file.compilation_context = ctx
            resolve_file_paths(file)

            file.process(ctx)

            expect(File.read(File.join(temp_dir, 'styles/some_file_res.css'))).to eq <<~CSS
              div {
                background: url("../images/image.png");
              }
              div {
                background: url("../images/image.png");
              }
            CSS
          end
        end
      end
    end
  end
end
