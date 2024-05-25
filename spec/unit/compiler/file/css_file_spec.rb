# frozen_string_literal: true

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_types/css_file'

module Epuber
  class Compiler
    module FileTypes
      describe CSSFile do
        describe 'FakeFS parts' do
          include FakeFS::SpecHelpers

          let(:ctx) do
            book = Book.new

            ctx = CompilationContext.new(book, book.default_target)
            ctx.file_resolver = FileResolver.new('/', '/.build')

            ctx
          end

          it 'finds linked files using url()' do
            source = <<~CSS
              div {
                background: url(image.png);
              }

              @font-face {
                font-family: 'MyFont';
                src: url('font.ttf');
              }

              @font-face {
                font-family: 'MyFont';
                src: url("font-italic.ttf");
              }

              @font-face {
                font-family: 'MyFont';
                src: url("../Fonts/font-bold.TTF");
              }
            CSS

            FileUtils.mkdir_p('/abc')
            File.write('/abc/some_file.css', source)
            FileUtils.touch('/abc/image.png')
            FileUtils.touch('/abc/font.ttf')
            FileUtils.touch('/abc/font-italic.ttf')
            FileUtils.mkdir_p('/Fonts')
            FileUtils.touch('/Fonts/font-bold.TTF')

            file = described_class.new('/abc/some_file.css')
            file.destination_path = 'abc/some_file_res.css'
            file.compilation_context = ctx
            resolve_file_paths(file)

            file.process(ctx)

            expect(File.read('/abc/some_file_res.css')).to eq <<~CSS
              div {
                background: url(image.png);
              }

              @font-face {
                font-family: 'MyFont';
                src: url('font.ttf');
              }

              @font-face {
                font-family: 'MyFont';
                src: url("font-italic.ttf");
              }

              @font-face {
                font-family: 'MyFont';
                src: url("../Fonts/font-bold.TTF");
              }
            CSS

            # files are added to file resolver
            expect(ctx.file_resolver.file_with_source_path('/abc/image.png')).not_to be_nil
            expect(ctx.file_resolver.file_with_source_path('/abc/font.ttf')).not_to be_nil
            expect(ctx.file_resolver.file_with_source_path('/abc/font-italic.ttf')).not_to be_nil
          end

          it 'modifies linked files using url()' do
            source = <<~CSS
              div {
                background: url(image.png);
              }
              div {
                background: url("image");
              }
            CSS

            FileUtils.mkdir_p('/abc/styles')
            File.write('/abc/styles/some_file.css', source)
            FileUtils.mkdir_p('/abc/images')
            FileUtils.touch('/abc/images/image.png')

            file = described_class.new('/abc/styles/some_file.css')
            file.destination_path = 'abc/styles/some_file_res.css'
            file.compilation_context = ctx
            resolve_file_paths(file)

            file.process(ctx)

            expect(File.read('/abc/styles/some_file_res.css')).to eq <<~CSS
              div {
                background: url(../images/image.png);
              }
              div {
                background: url("../images/image.png");
              }
            CSS
          end

          it 'reports error when linked file is not found' do
            source = <<~CSS
              div {
                background: url(image.png);
              }
            CSS

            FileUtils.mkdir_p('/abc/styles')
            File.write('/abc/styles/some_file.css', source)

            file = described_class.new('/abc/styles/some_file.css')
            file.destination_path = 'abc/styles/some_file_res.css'
            ctx.release_build = true
            file.compilation_context = ctx
            resolve_file_paths(file)

            # Act
            file.process(ctx)

            # Assert
            expect(UI.logger.formatted_messages).to eq <<~LOG.rstrip
              Not found file matching pattern `image.png` from context path abc/styles.
            LOG
          end
        end
      end
    end
  end
end
