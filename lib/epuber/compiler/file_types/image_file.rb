# encoding: utf-8

require 'rmagick'


module Epuber
  class Compiler
    module FileTypes
      require_relative 'source_file'

      class ImageFile < SourceFile
        # @param [Compiler::CompilationContext] compilation_context
        #
        def process(compilation_context)
          dest = final_destination_path
          source = abs_source_path

          return if FileUtils.uptodate?(dest, [source])

          img = Magick::Image::read(source).first

          resolution = img.columns * img.rows
          max_resolution = 3_000_000

          if resolution > max_resolution
            img = img.change_geometry("#{max_resolution}@>") do |width, height, b_img|
              UI.print_processing_debug_info("downscaling from resolution #{b_img.columns}x#{b_img.rows} to #{width}x#{height}")
              b_img.resize!(width, height)
            end

            FileUtils.mkdir_p(File.dirname(dest))

            img.write(dest)
          else
            # file is already old
            self.class.file_copy!(source, dest)
          end
        end
      end
    end
  end
end
