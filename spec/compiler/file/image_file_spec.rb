# encoding: utf-8

require_relative '../../spec_helper'

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

        it "copy file's content to destination" do
          img_source = 'test_project/images/001_Frie_9780804137508_art_r1_fmt.png'
          img_dest = File.join(@tmp_dir, 'dest_image.png')

          expect(File.exist?(img_source)).to be_truthy
          expect(File.exist?(img_dest)).to be_falsey

          file = ImageFile.new(img_source)
          file.destination_path = img_dest

          # hack lines, because this normally does FileResolver
          file.abs_source_path = file.source_path
          file.pkg_destination_path = file.destination_path
          file.final_destination_path = file.destination_path

          file.process(nil)

          expect(File.exist?(img_dest)).to be_truthy
          expect(FileUtils.compare_file(img_source, img_dest)).to eq true
        end

        it 'downscales the image when is too large'

        after do
          FileUtils.remove_entry(@tmp_dir)
        end
      end



    end
  end
end
