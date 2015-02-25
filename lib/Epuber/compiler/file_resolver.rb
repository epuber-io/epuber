# encoding: utf-8

module Epuber
  class Compiler
    class FileResolver

      # @return [String]
      #
      attr_reader :source_path

      # @return [String]
      #
      attr_reader :destination_path


      # @param source_path [String]
      # @param destination_path [String]
      #
      def initialize(source_path, destination_path)
        @source_path      = source_path
        @destination_path = destination_path
        @files            = {
          spine:    [],
          manifest: [],
          package:  [],
        }.freeze
      end

      # @param file [File, FileRequest]
      # @param type [Symbol]
      #      one of: :spine, :manifest or :package
      #
      def add_file(file, type: :manifest)
        resolve_destination_path(file)

        if type == :spine
          @files[:spine] << file unless @files[:spine].include?(file)
        end

        if type == :spine || type == :manifest
          @files[:manifest] << file unless @files[:manifest].include?(file)
        end

        if type == :spine || type == :manifest || type == :package
          @files[:package] << file unless @files[:package].include?(file)
        end
      end

      # @param file_request [FileRequest]
      #
      def add_files(file_request)
        find_files(file_request).each do |path|
          add_file(File.new(Epuber::Book::FileRequest.new(path)))
        end
      end

      # @param type [Symbol]
      #      one of: :spine, :manifest or :package
      #
      # @return [Array<File>, nil]
      #
      def files_of(type = :package)
        @files[type] if @files.include?(type)
      end

      # @param file_request [FileRequest]
      #
      # @return [File, nil]
      #
      def find_file_from_request(file_request)
        return if file_request.nil?

        files_of.find do |file|
          if file.file_request == file_request
            true
          elsif !file.source_path.nil?
            file.source_path == find_file(file_request, file_request.group)
          end
        end
      end

      # @param file_request [FileRequest]
      #
      # @return [Array<File>]
      #
      def find_files_from_request(file_request)
        return if file_request.nil?

        files_of.select do |file|
          if file.file_request == file_request
            true
          elsif !file.source_path.nil?
            file.source_path == find_file(file_request, file_request.group)
          end
        end
      end

      # @param from [File]
      # @param to [File]
      #
      # @return [String]
      #
      def relative_path(from, to)
        Pathname.new(to.destination_path).relative_path_from(Pathname.new(::File.dirname(from.destination_path))).to_s
      end


      private

      # @param file [Epuber::Compiler::File]
      # @return [nil]
      #
      def resolve_destination_path(file)
        if file.destination_path.nil?
          unless file.package_destination_path.nil?
            file.destination_path = ::File.expand_path(file.package_destination_path, destination_path)
            return
          end

          real_source_path = find_file(file, file.group)

          extname     = ::File.extname(real_source_path)
          new_extname = EXTENSIONS_RENAME[extname]

          dest_path = if new_extname.nil?
                        real_source_path
                      else
                        real_source_path.sub(/#{extname}$/, new_extname)
                      end

          abs_path = ::File.join(@destination_path, Compiler::EPUB_CONTENT_FOLDER, dest_path)

          file.destination_path = abs_path
          file.source_path      = real_source_path
        end
      end

      # @param file_or_pattern [String, Epuber::Compiler::File]
      # @param group [Symbol]
      # @return [String]
      #
      def find_file(file_or_pattern, group = nil)
        pattern = pattern_from(file_or_pattern)
        file_paths = find_files(file_or_pattern, group)

        raise "not found file matching pattern `#{pattern}`" if file_paths.empty?
        raise "found too many files for pattern `#{pattern}`, paths = #{file_paths}" if file_paths.count >= 2

        file_paths.first
      end

      # @param file_or_pattern [String, Epuber::Book::FileRequest]
      # @param group [Symbol]
      # @return [Array<String>]
      #
      def find_files(file_or_pattern, group = nil)
        pattern = pattern_from(file_or_pattern)

        group = file_or_pattern.group if group.nil? && file_or_pattern.is_a?(Epuber::Book::FileRequest)

        file_paths = file_paths_with_pattern("**/#{pattern}", group)
        file_paths = file_paths_with_pattern("**/#{pattern}.*", group) if file_paths.empty?

        file_paths
      end

      # @param pattern [String]
      # @param group [Symbol]
      # @return [Array<String>]
      #
      def file_paths_with_pattern(pattern, group = nil)
        file_paths = Dir.glob(pattern)

        file_paths.select! do |file_path|
          !file_path.include?(Config::WORKING_PATH)
        end

        # filter depend on group
        unless group.nil?
          file_paths.select! do |file_path|
            extname     = ::File.extname(file_path)
            group_array = GROUP_EXTENSIONS[group]

            raise "Unknown file group #{group.inspect}" if group_array.nil?

            group_array.include?(extname)
          end
        end

        file_paths
      end

      # @param file_or_pattern [String, File, FileRequest]
      # @return [String] only pattern
      #
      def pattern_from(file_or_pattern)
        if file_or_pattern.is_a?(File)
          file_or_pattern.file_request.source_pattern
        elsif file_or_pattern.is_a?(Epuber::Book::FileRequest)
          file_or_pattern.source_pattern
        elsif file_or_pattern.is_a?(String)
          file_or_pattern
        else
          raise "Unknown class #{file_or_pattern.class}"
        end
      end
    end
  end
end
