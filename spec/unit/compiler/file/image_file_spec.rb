# frozen_string_literal: true

require_relative '../../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_types/image_file'


module Epuber
  class Compiler
    module FileTypes
      describe ImageFile do
        before do
          @tmp_dir = Dir.mktmpdir
        end

        let(:ctx) do
          book = Book.new

          ctx = CompilationContext.new(book, book.default_target)
          ctx.file_resolver = FileResolver.new(@tmp_dir, File.join(@tmp_dir, '/.build'))

          ctx
        end

        after do
          FileUtils.remove_entry(@tmp_dir)
        end

        it "copy file's content to destination" do
          img_source = File.join(spec_root, '../test_project/images/001_Frie_9780804137508_art_r1_fmt.png')
          img_dest = File.join(@tmp_dir, 'dest_image.png')

          expect(File).to exist(img_source)
          expect(File).not_to exist(img_dest)

          file = described_class.new(img_source)
          file.destination_path = img_dest
          resolve_file_paths(file)

          file.compilation_context = ctx
          file.process(nil)

          expect(File).to exist(img_dest)
          expect(FileUtils.compare_file(img_source, img_dest)).to eq true
        end

        it 'downscales the image when is too large', expensive: true do
          source = File.join(spec_root, 'fixtures/6000x6000.png')
          dest = File.join(@tmp_dir, 'dest_image.png')

          source_magick_file = Magick::Image.read(source).first
          expect(source_magick_file.rows).to eq 6000
          expect(source_magick_file.columns).to eq 6000

          file = described_class.new(source)
          file.destination_path = dest
          resolve_file_paths(file)

          file.compilation_context = ctx
          file.process(nil)


          dest_magick_file = Magick::Image.read(dest).first
          expect(dest_magick_file.rows).not_to eq 6000
          expect(dest_magick_file.columns).not_to eq 6000
          expect(dest_magick_file.rows * dest_magick_file.columns).to be < 3_000_000
          expect(dest_magick_file.rows * dest_magick_file.columns).to be > 2_900_000
        end
      end
    end
  end
end
