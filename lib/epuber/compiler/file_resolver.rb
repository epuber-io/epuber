# encoding: utf-8

require 'unicode_normalize'



module Epuber
  class Compiler
    require_relative 'file_finders/normal'
    require_relative 'file_finders/imaginary'

    require_relative 'file_types/abstract_file'
    require_relative 'file_types/static_file'
    require_relative 'file_types/stylus_file'
    require_relative 'file_types/xhtml_file'
    require_relative 'file_types/bade_file'

    class FileResolver
      PATH_TYPES = [:spine, :manifest, :package, nil]

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

        if [:spine].include?(type)
          @spine_files << file unless @spine_files.include?(file)
        end

        if [:spine, :manifest].include?(type)
          @manifest_files << file unless @manifest_files.include?(file)
        end

        if [:spine, :manifest, :package].include?(type)
          @package_files << file unless @package_files.include?(file)
        end

        @files << file unless @files.include?(file)

        dest_finder.add_file(file.destination_path)

        unless file.file_request.nil?
          @request_to_files[file.file_request] << file
        end

        if file.respond_to?(:source_path) && !file.source_path.nil?
          @source_path_to_file[file.source_path] = file
        end
      end

      # Get instance of file from request instance
      #
      # @param [Book::FileRequest] file_request
      #
      # @return [FileTypes::AbstractFile, Array<FileTypes::AbstractFile>]
      #
      def file_from_request(file_request)
        files = @request_to_files[file_request]

        if file_request.only_one
          files.first  # @request_to_files always returns array, see #initialize method
        else
          files
        end
      end

      # Get instance of file from source path
      #
      # @param [String] source_path
      #
      # @return [FileTypes::AbstractFile]
      #
      def file_with_source_path(source_path)
        @source_path_to_file[source_path.unicode_normalize]
      end

      # Method to get instance of file on specific path
      #
      # @param [String] path  path to file from destination folder
      # @param [String] path_type  path type of path (:spine, :manifest or :package)
      #
      # @return [FileTypes::AbstractFile]
      #
      def file_with_destination_path(path, path_type = :manifest)
        final_path = File.join(self.class.path_for(destination_path, path_type), path.unicode_normalize)
        @final_destination_path_to_file[final_path]
      end

      # @param [Epuber::Compiler::File, Epuber::Book::FileRequest, String] from
      # @param [Epuber::Compiler::File, Epuber::Book::FileRequest, String] to
      #
      # @return [String]
      #
      def relative_path(from, to)
        from_path = if from.is_a?(String)
                      from
                    elsif from.is_a?(Epuber::Compiler::File)
                      from.destination_path
                    elsif from.is_a?(Epuber::Book::FileRequest)
                      find_file_from_request(from).destination_path
                    end

        from_path = ::File.dirname(from_path) unless ::File.directory?(from_path)

        to_path = if to.is_a?(String)
                    to
                  elsif to.is_a?(Epuber::Compiler::File)
                    to.destination_path
                  elsif to.is_a?(Epuber::Book::FileRequest)
                    find_file_from_request(to).destination_path
                  end

        Pathname.new(to_path).relative_path_from(Pathname.new(from_path)).to_s
      end

      # @param [Epuber::Compiler::File, Epuber::Book::FileRequest, String] file
      #
      # @return [String]
      #
      def relative_path_from_source_root(file)
        return if file.nil?
        relative_path(source_path, file)
      end

      # @param [Epuber::Compiler::File, Epuber::Book::FileRequest, String] file
      #
      # @return [String]
      #
      def relative_path_from_package_root(file)
        return if file.nil?
        relative_path(destination_path, file)
      end



      # Method to find all files that should be deleted, because they are not in files in receiver
      #
      # @return [Array<String>] list of files that should be deleted in destination directory
      #
      def unneeded_files_in_destination
        requested_paths = files.map do |file|
          file.destination_path
        end

        existing_paths = FileFinders::Normal.new(destination_path).find_all('*')

        unnecessary_paths = existing_paths - requested_paths

        unnecessary_paths.select! do |path|
          !::File.directory?(File.join(destination_path, path))
        end

        unnecessary_paths
      end

      private

      # @param file [Epuber::Compiler::AbstractFile]
      #
      # @return [nil]
      #
      def resolve_destination_path(file)
        if file.final_destination_path.nil?
          real_source_path = if file.respond_to?(:source_path) && !file.source_path.nil?
                               file.source_path
                             else
                               find_file(file, file.group)
                             end

          extname     = File.extname(real_source_path)
          new_extname = FileFinders::EXTENSIONS_RENAME[extname]

          dest_path = if new_extname.nil?
                        real_source_path
                      else
                        real_source_path.sub(/#{Regexp.escape(extname)}$/, new_extname)
                      end

          file.destination_path = dest_path
          file.pkg_destination_path = File.join(self.class.path_for(file.path_type), dest_path)
          file.final_destination_path = File.join(destination_path, file.pkg_destination_path)

          @final_destination_path_to_file[file.final_destination_path] = file
        end
      end



      ##################################################################################################################

      private

      # @param [String] extname  extension of file
      #
      # @return [Class]
      #
      def self.file_class_for(extname)
        mapping = {
          '.styl'  => FileTypes::StylusFile,
          '.bade'  => FileTypes::BadeFile,
          '.xhtml' => FileTypes::XHTMLFile,
          '.html'  => FileTypes::XHTMLFile,
        }

        mapping[extname] || FileTypes::StaticFile
      end

      # @param [String] root_path  path to root of the package
      # @param [Symbol] path_type  path type of file
      #
      def self.path_for(root_path = nil, path_type)
        case path_type
          when :spine, :manifest
            if root_path.nil?
              Compiler::EPUB_CONTENT_FOLDER
            else
              File.join(root_path, Compiler::EPUB_CONTENT_FOLDER)
            end
          when :package
            root_path || '.'
          else
            nil
        end
      end
    end
  end
end
