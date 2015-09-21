# encoding: utf-8


module Epuber
  class Compiler
    module FileTypes
      require_relative 'abstract_file'

      class SourceFile < AbstractFile

        # @return [String] relative source path
        #
        attr_reader :source_path

        # @return [String] absolute source path
        #
        attr_accessor :abs_source_path

        # @return [Epuber::Book::FileRequest]
        #
        attr_accessor :file_request

        # @param [String] source_path  relative path from project root to source file
        #
        def initialize(source_path)
          @source_path = source_path
        end

        def default_file_copy
          if self.class.file_copy?(abs_source_path, final_destination_path)
            UI.print_processing_debug_info("Copying to #{pkg_destination_path}")
            self.class.file_copy!(abs_source_path, final_destination_path)
          end
        end

        def write_compiled(content)
          if self.class.write_to_file?(content, final_destination_path)
            UI.print_processing_debug_info("Writing compiled version to #{pkg_destination_path}")
            self.class.write_to_file!(content, final_destination_path)
          end
        end

        def write_processed(content)
          if self.class.write_to_file?(content, final_destination_path)
            UI.print_processing_debug_info("Writing processed version to #{pkg_destination_path}")
            self.class.write_to_file!(content, final_destination_path)
          end
        end
      end
    end
  end
end
