# frozen_string_literal: true

require 'active_support/core_ext/object/try'

module Epuber
  class Compiler
    require_relative 'file_finders/normal'
    require_relative 'file_finders/imaginary'

    require_relative 'file_types/abstract_file'
    require_relative 'file_types/generated_file'
    require_relative 'file_types/static_file'
    require_relative 'file_types/stylus_file'
    require_relative 'file_types/xhtml_file'
    require_relative 'file_types/bade_file'
    require_relative 'file_types/image_file'
    require_relative 'file_types/nav_file'
    require_relative 'file_types/opf_file'
    require_relative 'file_types/mime_type_file'
    require_relative 'file_types/container_xml_file'
    require_relative 'file_types/ibooks_display_options_file'
    require_relative 'file_types/coffee_script_file'
    require_relative 'file_types/css_file'

    class FileResolver
      class ResolveError < StandardError; end

      PATH_TYPES = [:spine, :manifest, :package, nil].freeze

      # @return [String] path where should look for source files
      #
      attr_reader :source_path

      # @return [String] path where will be stored result files
      #
      attr_reader :destination_path


      # @return [Array<FileTypes::Abstract>] all files that will be in spine
      #
      attr_reader :spine_files

      # @return [Array<FileTypes::Abstract>] all files that has to be in manifest file (OPF)
      #
      attr_reader :manifest_files

      # @return [Array<FileTypes::Abstract>] all files that will be copied to EPUB package
      #
      attr_reader :package_files

      # @return [Array<FileTypes::Abstract>] totally all files
      #
      attr_reader :files


      # @return [FileFinders::Normal]
      #
      attr_reader :source_finder

      # @return [FileFinders::Imaginary]
      #
      attr_reader :dest_finder


      # @param [String] source_path
      # @param [String] destination_path
      #
      def initialize(source_path, destination_path)
        @source_finder = FileFinders::Normal.new(source_path.unicode_normalize)
        @source_finder.ignored_patterns << ::File.join(Config::WORKING_PATH, '**')

        @dest_finder = FileFinders::Imaginary.new(destination_path.unicode_normalize)

        @source_path      = source_path.unicode_normalize
        @destination_path = destination_path.unicode_normalize

        @spine_files    = []
        @manifest_files = []
        @package_files  = []
        @files          = []

        @request_to_files = Hash.new { |hash, key| hash[key] = [] }
        @final_destination_path_to_file = {}
        @source_path_to_file = {}
        @abs_source_path_to_file = {}
      end

      # @param [Epuber::Book::FileRequest] file_request
      #
      def add_file_from_request(file_request, path_type = :manifest)
        if file_request.only_one
          file_path = @source_finder.find_file(file_request.source_pattern, groups: file_request.group)
          file_class = self.class.file_class_for(File.extname(file_path))

          file = file_class.new(file_path)
          file.file_request = file_request
          file.path_type = path_type

          add_file(file)
        else
          file_paths = @source_finder.find_all(file_request.source_pattern, groups: file_request.group)
          file_paths.map do |path|
            file_class = self.class.file_class_for(File.extname(path))

            file = file_class.new(path)
            file.file_request = file_request
            file.path_type = path_type

            add_file(file)
          end
        end
      end

      # @param [Epuber::Compiler::FileTypes::AbstractFile] file
      #
      def add_file(file)
        type = file.path_type

        unless PATH_TYPES.include?(type)
          raise "Unknown file.path_type #{type.inspect}, expected are :spine, :manifest, :package or nil"
        end

        resolve_destination_path(file)

        existing_file = @final_destination_path_to_file[file.final_destination_path]

        # save mapping from file_request to file, file_request can be different, but result file could be the same ...
        @request_to_files[file.file_request] << (existing_file || file) unless file.try(:file_request).nil?

        # return existing file if already exists, new file will be thrown away
        return existing_file unless existing_file.nil?

        @spine_files << file if [:spine].include?(type)

        @manifest_files << file if %i[spine manifest].include?(type)

        @package_files << file if %i[spine manifest package].include?(type)

        @files << file


        dest_finder.add_file(file.destination_path)

        @final_destination_path_to_file[file.final_destination_path] = file

        @source_path_to_file[file.source_path] = file if file.respond_to?(:source_path) && !file.source_path.nil?

        return unless file.respond_to?(:abs_source_path) && !file.abs_source_path.nil?

        @abs_source_path_to_file[file.abs_source_path] = file
      end

      # Get instance of file from request instance
      #
      # @param [Book::FileRequest] file_request
      #
      # @return [FileTypes::AbstractFile, Array<FileTypes::AbstractFile>]
      #
      def file_from_request(file_request)
        files = @request_to_files[file_request]

        if files.empty? && file_request.only_one
          begin
            path  = @source_finder.find_file(file_request.source_pattern, groups: file_request.group)
            file  = file_with_source_path(path)

            unless file.nil?
              @request_to_files[file_request] = file
              files = [file]
            end
          rescue FileFinders::FileNotFoundError, FileFinders::MultipleFilesFoundError
            # noop
          end
        end

        if file_request.only_one
          files.first # @request_to_files always returns array, see #initialize method
        else
          files
        end
      end

      # Get instance of file from source path, but this is relative path from project root, if you want to find
      # file with absolute source path see #file_with_abs_source_path
      #
      # @param [String] source_path
      #
      # @return [FileTypes::AbstractFile]
      #
      def file_with_source_path(source_path)
        source_path = source_path.unicode_normalize
        @source_path_to_file[source_path] || @abs_source_path_to_file[source_path]
      end

      # Method to get instance of file on specific path
      #
      # @param [String] path  path to file from destination folder
      # @param [String] path_type  path type of path (:spine, :manifest or :package)
      #
      # @return [FileTypes::AbstractFile]
      #
      def file_with_destination_path(path, path_type = :manifest)
        final_path = File.join(*self.class.path_comps_for(destination_path, path_type), path.unicode_normalize)
        @final_destination_path_to_file[path] || @final_destination_path_to_file[final_path]
      end

      # Method to find all files that should be deleted, because they are not in files in receiver
      #
      # @return [Array<String>] list of files that should be deleted in destination directory
      #
      def unneeded_files_in_destination
        requested_paths = files.map(&:pkg_destination_path)

        existing_paths = FileFinders::Normal.new(destination_path).find_all('*')

        unnecessary_paths = existing_paths - requested_paths

        unnecessary_paths.reject! do |path|
          ::File.directory?(File.join(destination_path, path))
        end

        unnecessary_paths
      end

      ##################################################################################################################

      class << self
        # @param [String] path  path to some file
        #
        # @return [String] path with changed extension
        #
        def renamed_file_with_path(path)
          extname     = File.extname(path)
          new_extname = FileFinders::EXTENSIONS_RENAME[extname]

          if new_extname.nil?
            path
          else
            path.sub(/#{Regexp.escape(extname)}$/, new_extname)
          end
        end

        # @param [String] extname  extension of file
        #
        # @return [Class]
        #
        def file_class_for(extname)
          mapping = {
            '.styl' => FileTypes::StylusFile,
            '.css' => FileTypes::CSSFile,

            '.coffee' => FileTypes::CoffeeScriptFile,

            '.bade' => FileTypes::BadeFile,
            '.xhtml' => FileTypes::XHTMLFile,
            '.html' => FileTypes::XHTMLFile,

            '.jpg' => FileTypes::ImageFile,
            '.jpeg' => FileTypes::ImageFile,
            '.png' => FileTypes::ImageFile,
          }

          mapping[extname] || FileTypes::StaticFile
        end

        # @param [String] root_path  path to root of the package
        # @param [Symbol] path_type  path type of file
        #
        # @return [Array<String>] path components
        #
        def path_comps_for(root_path, path_type)
          case path_type
          when :spine, :manifest
            Array(root_path) + [Compiler::EPUB_CONTENT_FOLDER]
          when :package
            Array(root_path)
          end
        end
      end

      private

      # @param [Epuber::Compiler::AbstractFile] file
      #
      # @return [nil]
      #
      def resolve_destination_path(file)
        return unless file.final_destination_path.nil?

        dest_path = if file.respond_to?(:source_path) && !file.source_path.nil?
                      file.abs_source_path = File.expand_path(file.source_path, source_path)
                      self.class.renamed_file_with_path(file.source_path)
                    elsif !file.destination_path.nil?
                      file.destination_path
                    else
                      raise ResolveError, <<~ERROR
                        What should I do with file that doesn't have source path or destination path? file: #{file.inspect}
                      ERROR
                    end

        file.destination_path = dest_path
        file.pkg_destination_path = File.join(*self.class.path_comps_for(nil, file.path_type), dest_path)
        file.final_destination_path = File.join(destination_path, file.pkg_destination_path)
      end
    end
  end
end
