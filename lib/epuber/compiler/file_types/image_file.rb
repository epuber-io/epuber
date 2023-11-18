# frozen_string_literal: true

require 'rmagick'

module Epuber
  class Compiler
    module FileTypes
      require_relative 'source_file'

      class ImageFile < SourceFile
        # @param [Compiler::CompilationContext] _compilation_context
        #
        def process(_compilation_context)
          return if destination_file_up_to_date?

          dest = final_destination_path
          source = abs_source_path

          img = Magick::Image.read(source).first

          resolution = img.columns * img.rows
          max_resolution = 3_000_000

          if resolution > max_resolution
            img = img.change_geometry("#{max_resolution}@>") do |width, height, b_img|
              UI.print_processing_debug_info(<<~MSG)
                downscaling from resolution #{b_img.columns}x#{b_img.rows} to #{width}x#{height}
              MSG
              b_img.resize!(width, height)
            end

            FileUtils.mkdir_p(File.dirname(dest))

            img.write(dest)
          else
            # file is already old
            self.class.file_copy!(source, dest)
          end

          update_metadata!
        end
      end
    end
  end
end
