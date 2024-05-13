# frozen_string_literal: true

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
          super()

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

        # @return [Set<Symbol>] list of properties
        #
        def properties
          file_request&.properties || super
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
            UI.print_processing_debug_info(<<~MSG)
              Not writing to disk ... compiled version at #{pkg_destination_path} is same
            MSG
          end
        end

        def write_processed(content)
          if self.class.write_to_file?(content, final_destination_path)
            UI.print_processing_debug_info("Writing processed version to #{pkg_destination_path}")
            self.class.write_to_file!(content, final_destination_path)
          else
            UI.print_processing_debug_info(<<~MSG)
              Not writing to disk ... processed version at #{pkg_destination_path} is same
            MSG
          end
        end

        def self.resolve_relative_file(destination_path, pattern, file_resolver, group: nil, location: nil)
          dirname = File.dirname(destination_path)

          begin
            new_path = file_resolver.dest_finder.find_file(pattern, groups: group, context_path: dirname)
          rescue FileFinders::FileNotFoundError, FileFinders::MultipleFilesFoundError
            begin
              new_path = XHTMLProcessor.resolved_link_to_file(pattern,
                                                              group,
                                                              dirname,
                                                              file_resolver.source_finder).to_s
            rescue XHTMLProcessor::UnparseableLinkError,
                   FileFinders::FileNotFoundError,
                   FileFinders::MultipleFilesFoundError => e
              UI.warning(e.to_s, location: location)
              return nil
            end
          end

          pkg_abs_path = File.expand_path(new_path, dirname).unicode_normalize
          pkg_new_path = Pathname.new(pkg_abs_path)
                                 .relative_path_from(Pathname.new(file_resolver.source_path))
                                 .to_s

          file_class = FileResolver.file_class_for(File.extname(new_path))
          file = file_class.new(pkg_new_path)
          file.path_type = :manifest
          file_resolver.add_file(file)

          FileResolver.renamed_file_with_path(new_path)
        end
      end
    end
  end
end
