# encoding: utf-8

module Epuber
  class Compiler
    class FileResolver
      class FileNotFoundError < ::StandardError; end
      class MultipleFilesFoundError < ::StandardError; end

      GROUP_EXTENSIONS = {
        text:  %w(.xhtml .html .bade .rxhtml),
        image: %w(.png .jpg .jpeg),
        font:  %w(.otf .ttf),
        style: %w(.css .styl),
      }.freeze

      STATIC_EXTENSIONS = %w(.xhtml .html .png .jpg .jpeg .otf .ttf .css).freeze

      EXTENSIONS_RENAME = {
        '.styl'   => '.css',

        '.bade'   => '.xhtml',
        '.rxhtml' => '.xhtml',
        '.md'     => '.xhtml',
      }.freeze

      # @return [String] path where should look for source files
      #
      attr_reader :source_path

      # @return [String] path where will be stored result files
      #
      attr_reader :destination_path


      # @param [String] source_path
      # @param [String] destination_path
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

      # @param [Epuber::Compiler::File, FileRequest] file
      # @param [Symbol] type
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

        unless file.file_request.nil?
          _request_to_file_map_cache[file.file_request] = file
        end
      end

      # @param [FileRequest] file_request
      #
      def add_files(file_request)
        find_files(file_request).each do |path|
          add_file(File.new(Epuber::Book::FileRequest.new(path)))
        end
      end

      # @param [Symbol] type
      #      one of: :spine, :manifest or :package
      #
      # @return [Array<File>, nil]
      #
      def files_of(type = :package)
        @files[type] if @files.include?(type)
      end

      # @param [FileRequest] file_request
      #
      # @return [File, nil]
      #
      def find_file_from_request(file_request)
        return if file_request.nil?

        cached = _request_to_file_map_cache[file_request]
        return cached unless cached.nil?

        founded = files_of.find do |file|
          if file.file_request == file_request
            true
          elsif !file.source_path.nil?
            file.source_path == find_file(file_request, file_request.group)
          end
        end

        _request_to_file_map_cache[file_request] = founded

        founded
      end

      # @param [FileRequest] file_request
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

      # @param [String] destination_path
      #
      # @return [File]
      #
      def find_file_with_destination_path(destination_path)
        file_paths = files_of.select do |file|
          file.destination_path == destination_path
        end

        assert_one_file_path(file_paths, destination_path)

        file_paths.first
      end

      # @param [String] pattern
      # @param [String] context_path
      # @param [Symbol] group
      #
      # @return [File]
      #
      def find_file_with_destination_pattern(pattern, context_path, group)
        unless pattern.include?('*')
          # don't even try, when there is star char
          begin
            # try to find file with exact path
            return find_file_with_destination_path(::File.expand_path(pattern, context_path))

          rescue FileNotFoundError
            # not found, skip this and try to find with pattern
          end
        end

        extensions = GROUP_EXTENSIONS[group]
        raise "Unknown group #{group.inspect}" if extensions.nil?

        regexp_extensions = extensions.map { |ext| Regexp.escape(ext) }.join('|')
        complete_path = ::File.expand_path(::File.dirname(pattern), context_path)
        shorter_pattern = ::File.basename(pattern)

        regex = /^#{Regexp.escape(complete_path)}\/#{shorter_pattern}(?:#{regexp_extensions})$/

        _find_file_obj(pattern) do |file|
          regex =~ file.destination_path
        end
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
        relative_path(self.source_path, file)
      end

      # @param [Epuber::Compiler::File, Epuber::Book::FileRequest, String] file
      #
      # @return [String]
      #
      def relative_path_from_package_root(file)
        return if file.nil?
        relative_path(self.destination_path, file)
      end

      # @param file_or_pattern [String, Epuber::Compiler::File]
      # @param group [Symbol]
      #
      # @return [String] relative path from source path to founded file
      #
      def find_file(file_or_pattern, group = nil, context_path: source_path)
        pattern = pattern_from(file_or_pattern)
        file_paths = find_files(file_or_pattern, group, context_path: context_path)

        assert_one_file_path(file_paths, pattern)

        file_paths.first
      end


      private

      def _request_to_file_map_cache
        @request_to_file_map_cache ||= {}
      end

      # @param file [Epuber::Compiler::File]
      #
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

      # @param [String] failure_message
      #
      # @yieldparam [Epuber::Compiler::File]
      #
      # @return [Epuber::Compiler::File]
      #
      def _find_file_obj(failure_message)
        file_objs = files_of.select do |file|
          yield file
        end

        assert_one_file_path(file_objs, failure_message)
        file_objs.first
      end

      # @param file_or_pattern [String, Epuber::Book::FileRequest]
      # @param group [Symbol]
      #
      # @return [Array<String>]
      #
      def find_files(file_or_pattern, group = nil, context_path: source_path)
        pattern = pattern_from(file_or_pattern)

        group = file_or_pattern.group if group.nil? && file_or_pattern.is_a?(Epuber::Book::FileRequest)

        file_paths = file_paths_with_pattern("**/#{pattern}", group, context_path: context_path)
        file_paths = file_paths_with_pattern("**/#{pattern}.*", group, context_path: context_path) if file_paths.empty?

        file_paths
      end

      # @param [Array<String>] file_paths list of founded paths to files
      # @param [String] pattern pattern which will be included in raised error
      #
      # @raise FileNotFoundError
      # @raise MultipleFilesFoundError
      #
      # @return nil
      #
      def assert_one_file_path(file_paths, pattern)
        raise FileNotFoundError, "not found file matching pattern `#{pattern}`" if file_paths.empty?
        raise MultipleFilesFoundError, "found too many files for pattern `#{pattern}`, paths = #{file_paths}" if file_paths.count >= 2
      end

      # @param [String] pattern
      # @param [Symbol] group
      # @return [Array<String>]
      #
      def file_paths_with_pattern(pattern, group = nil, context_path: source_path)
        full_pattern = ::File.expand_path(pattern, context_path)
        file_paths = Dir.glob(full_pattern)

        file_paths.reject! do |file_path|
          file_path.include?(Config::WORKING_PATH)
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

        file_paths.map do |path|
          path.sub(::File.join(context_path, ''), '')
        end
      end

      # @param [String, File, FileRequest] file_or_pattern
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
