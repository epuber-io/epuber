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

      # @return [SortedSet<FileTypes::Abstract>] all files that will be copied to EPUB package
      #
      attr_reader :package_files

      # @return [SortedSet<FileTypes::Abstract>] totally all files
      #
      attr_reader :files


      # @param [String] source_path
      # @param [String] destination_path
      #
      def initialize(source_path, destination_path)
        @finder = FileFinders::Normal.new(source_path)
        @finder.ignored_patterns << ::File.join(Config::WORKING_PATH, '**')

        @source_path      = source_path.unicode_normalize
        @destination_path = destination_path.unicode_normalize

        @spine_files = SortedSet.new
        @manifest_files = SortedSet.new
        @package_files = SortedSet.new
        @files = SortedSet.new
      end

      # @param [Epuber::Book::FileRequest] file_request
      #
      def add_file_from_request(file_request, path_type = :manifest)
        file_path = @finder.find_file(file_request.source_pattern, groups: file_request.group)
        file_class = self.class.file_class_for(File.extname(file_path))

        file = file_class.new(file_path)
        file.file_request = file_request
        file.path_type = path_type

        add_file(file)
      end

      # @param [Epuber::Compiler::FileTypes::AbstractFile] file
      #
      def add_file(file)
        type = file.path_type

        unless [:spine, :manifest, :package, nil].include?(type)
          raise "Unknown file.path_type #{type.inspect}, expected are :spine, :manifest, :package or nil"
        end

        resolve_destination_path(file)

        if [:spine].include?(type)
          @spine_files << file
        end

        if [:spine, :manifest].include?(type)
          @manifest_files << file
        end

        if [:spine, :manifest, :package].include?(type)
          @package_files << file
        end

        @files << file

        unless file.file_request.nil?
          _request_to_file_map_cache[file.file_request] = file
        end
        if file.respond_to?(:source_path) && !file.source_path.nil?
          _source_path_to_file_map[file.source_path] = file
        end
      end

      # @param [FileRequest] file_request
      #
      def add_files(file_request)
        find_files(file_request).each do |path|
          add_file(File.new(Epuber::Book::FileRequest.new(path)))
        end
      end

      # @param [FileRequest] file_request
      #
      # @return [File, nil]
      #
      def find_file_from_request(file_request)
        return if file_request.nil?

        cached = _request_to_file_map_cache[file_request]
        return cached unless cached.nil?

        founded = @manifest_files.find do |file|
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

        @manifest_files.select do |file|
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
      def find_file_with_destination_path(destination_path, groups, context_path)
        file = _destination_path_to_file_map[destination_path]
        file_paths = [file].compact

        @finder.assert_one_file(file_paths, pattern: destination_path, groups: groups, context_path: context_path)

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
            return find_file_with_destination_path(::File.expand_path(pattern, context_path), group, context_path)

          rescue FileFinders::FileNotFoundError
            # not found, skip this and try to find with pattern
          end
        end

        extensions = FileFinders::GROUP_EXTENSIONS[group]
        raise "Unknown group #{group.inspect}" if extensions.nil?

        regexp_extensions = extensions.map { |ext| Regexp.escape(ext) }.join('|')
        complete_path = ::File.expand_path(::File.dirname(pattern), context_path)
        shorter_pattern = ::File.basename(pattern)

        regex = /^#{Regexp.escape(complete_path)}\/#{shorter_pattern}(?:#{regexp_extensions})$/

        _find_file_obj(pattern, group, context_path) do |file|
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

      # @param [String] pattern
      # @param [Symbol] group
      #
      # @return [String] relative path from source path to founded file
      #
      def find_file(pattern, group = nil, context_path: source_path)
        @finder.find_file(pattern, groups: group, context_path: context_path)
      end

      # @param [String] source_path
      #
      # @return [File]
      #
      def file_with_source_path(source_path)
        _source_path_to_file_map[source_path.unicode_normalize]
      end

      private

      def _request_to_file_map_cache
        @_request_to_file_map_cache ||= {}
      end

      def _source_path_to_file_map
        @_source_path_to_file_map ||= {}
      end

      def _destination_path_to_file_map
        @_destination_path_to_file_map ||= {}
      end

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

          extname     = ::File.extname(real_source_path)
          new_extname = FileFinders::EXTENSIONS_RENAME[extname]

          dest_path = if new_extname.nil?
                        real_source_path
                      else
                        real_source_path.sub(/#{extname}$/, new_extname)
                      end

          file.destination_path = dest_path
          file.final_destination_path = ::File.join(destination_path, Compiler::EPUB_CONTENT_FOLDER, dest_path)

          # TODO: uncomment following lines and resolve duplicate items
          #
          # if _destination_path_to_file_map.key?(file.destination_path)
          #   raise "Duplicate entry for result path #{file.destination_path}"
          # end

          _destination_path_to_file_map[file.destination_path] = file
        end
      end

      #
      # @yieldparam [Epuber::Compiler::File]
      #
      # @return [Epuber::Compiler::File]
      #
      def _find_file_obj(pattern, group, context_path)
        file_objs = files_of.select do |file|
          yield file
        end

        @finder.assert_one_file(file_objs, pattern: pattern, groups: group, context_path: context_path)

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

        @finder.find_files(pattern, groups: group, context_path: context_path)
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
    end
  end
end
