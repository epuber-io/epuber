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

        # return [Array<String>]
        #
        def find_dependencies
          []
        end

        def process(_compilation_context)
          # do nothing
        end

        # Source file does not change from last build
        # @warning Using only this method can cause not updating files that are different for targets
        #
        # @return [Bool]
        #
        def source_file_up_to_date?
          return false unless compilation_context.incremental_build?

          source_db = compilation_context.source_file_database
          source_db.up_to_date?(source_path)
        end

        # Source file does not change from last build of this target
        #
        # @return [Bool]
        #
        def destination_file_up_to_date?
          return false unless compilation_context.incremental_build?

          source_db = compilation_context.source_file_database
          target_db = compilation_context.target_file_database

          destination_file_exist? && # destination file must exist
            target_db.up_to_date?(source_path) && # source file must be up-to-date from last build of this target
            source_db.file_stat_for(source_path) == target_db.file_stat_for(source_path)
        end

        # Final destination path exist
        #
        # @return [Bool]
        #
        def destination_file_exist?
          File.exist?(final_destination_path)
        end

        # Updates information about source file in file databases
        #
        # @return [nil]
        #
        def update_metadata!
          compilation_context.source_file_database.update_metadata(source_path)
          compilation_context.target_file_database.update_metadata(source_path)
        end

        def default_file_copy
          if destination_file_up_to_date?
            UI.print_processing_debug_info("Destination path #{pkg_destination_path} is up-to-date")
          else
            UI.print_processing_debug_info("Copying to #{pkg_destination_path}")
            self.class.file_copy!(abs_source_path, final_destination_path)
          end

          update_metadata!
        end

        def write_compiled(content)
          if self.class.write_to_file?(content, final_destination_path)
            UI.print_processing_debug_info("Writing compiled version to #{pkg_destination_path}")
            self.class.write_to_file!(content, final_destination_path)
          else
            UI.print_processing_debug_info("Not writing to disk ... compiled version at #{pkg_destination_path} is same")
          end
        end

        def write_processed(content)
          if self.class.write_to_file?(content, final_destination_path)
            UI.print_processing_debug_info("Writing processed version to #{pkg_destination_path}")
            self.class.write_to_file!(content, final_destination_path)
          else
            UI.print_processing_debug_info("Not writing to disk ... processed version at #{pkg_destination_path} is same")
          end
        end
      end
    end
  end
end
