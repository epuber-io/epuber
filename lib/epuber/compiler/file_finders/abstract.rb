# encoding: utf-8

require 'unicode_normalize'


module Epuber
  class Compiler
    module FileFinders
      class FileNotFoundError < ::StandardError
        # @return [String]
        #
        attr_reader :pattern

        # @return [String]
        #
        attr_reader :context_path

        # @param [String] pattern
        # @param [String] context_path
        #
        def initialize(pattern, context_path)
          @pattern = pattern
          @context_path = context_path
        end

        def to_s
          "Not found file matching pattern `#{pattern}` from context path #{context_path}."
        end
      end

      class MultipleFilesFoundError < ::StandardError
        # @return [Array<String>]
        #
        attr_reader :files_paths

        # @return [Array<Symbol>]
        #
        attr_reader :groups

        # @return [String]
        #
        attr_reader :pattern

        # @return [String]
        #
        attr_reader :context_path

        # @param [String] pattern  original pattern for searching
        # @param [Symbol] groups  list of groups
        # @param [String] context_path  context path of current searching
        # @param [Array<String>] files_paths  list of founded files
        #
        def initialize(pattern, groups, context_path, files_paths)
          @pattern = pattern
          @groups = groups
          @context_path = context_path
          @files_paths = files_paths
        end

        def to_s
          str = "Found too many files for pattern `#{pattern}` from context path #{context_path}"
          str += ", file groups #{groups.map(:inspect)}" unless groups.nil?
          str + ", founded files #{files_paths}"
        end
      end

      BINARY_EXTENSIONS = %w(.png .jpeg .jpg .otf .ttf)
      STATIC_EXTENSIONS = BINARY_EXTENSIONS + %w(.css .js)

      GROUP_EXTENSIONS = {
        text:   %w(.xhtml .html .bade),
        image:  %w(.png .jpg .jpeg),
        font:   %w(.otf .ttf),
        style:  %w(.css .styl),
        script: %w(.js),
      }

      EXTENSIONS_RENAME = {
        '.styl' => '.css',

        '.bade' => '.xhtml',
      }

      class Abstract

        # @return [String] path where should look for source files
        #
        attr_reader :source_path

        # @return [Array<String>]
        #
        attr_accessor :ignored_patterns


        # @param [String] source_path
        #
        def initialize(source_path)
          @source_path = source_path.unicode_normalize.freeze
          @source_path_abs = ::File.expand_path(@source_path).unicode_normalize.freeze
          @ignored_patterns = []
        end


        def assert_one_file(files, pattern: nil, groups: nil, context_path: nil)
          raise FileNotFoundError.new(pattern, context_path) if files.empty?
          raise MultipleFilesFoundError.new(pattern, groups, context_path, files) if files.count >= 2
        end

        # Method for finding file from context_path, if there is not matching file, it will continue to search from
        # #source_path and after that it tries to search recursively from #source_path.
        #
        # When it founds too many (more than two) it will raise MultipleFilesFoundError
        #
        # @param [String] pattern  pattern of the desired files
        # @param [Symbol] groups  list of group names, nil or empty array for all groups, for valid values see GROUP_EXTENSIONS
        # @param [String] context_path  path for root of searching, it is also defines start folder of relative path
        #
        # @return [Array<String>] list of founded files
        #
        def find_file(pattern, groups: nil, context_path: nil, search_everywhere: true)
          files = find_files(pattern, groups: groups, context_path: context_path, search_everywhere: search_everywhere)
          assert_one_file(files, pattern: pattern, groups: groups, context_path: context_path)
          files.first
        end

        # Method for finding files from context_path, if there is not matching file, it will continue to search from
        # #source_path and after that it tries to search recursively from #source_path.
        #
        # @param [String] pattern  pattern of the desired files
        # @param [Array<Symbol>] groups  list of group names, nil or empty array for all groups, for valid values see GROUP_EXTENSIONS
        # @param [String] context_path  path for root of searching, it is also defines start folder of relative path
        #
        # @return [Array<String>] list of founded files
        #
        def find_files(pattern, groups: nil, context_path: nil, search_everywhere: true)
          files = []
          searching_path = context_path

          unless searching_path.nil?
            searching_path = ::File.expand_path(context_path, @source_path_abs)

            unless searching_path.start_with?(@source_path_abs)
              raise "You can't search from folder (#{searching_path}) that is not sub folder of the source_path (#{source_path}) expanded to (#{@source_path_abs})."
            end

            files = __find_files(pattern, groups, searching_path)
          end

          if files.empty? && context_path != source_path
            files = __find_files(pattern, groups, @source_path_abs, searching_path || @source_path_abs)
          end

          if files.empty? && search_everywhere && !pattern.start_with?('**')
            files = __find_files('**/' + pattern, groups, @source_path_abs, searching_path || @source_path_abs)
          end

          files
        end

        # Looks for all files from #source_path recursively
        #
        # @param [String] pattern  pattern of the desired files
        # @param [Array<Symbol>] groups  list of group names, nil or empty array for all groups, for valid values see GROUP_EXTENSIONS
        # @param [String] context_path  path for root of searching, it is also defines start folder of relative path
        #
        # @return [Array<String>] list of founded files
        #
        def find_all(pattern, groups: nil, context_path: @source_path_abs)
          __find_files('**/' + pattern, groups, context_path)
        end

        # @param [Array<String>] paths  list of file paths
        # @param [Array<Symbol>] groups  list of groups to filter file paths
        #
        # @return [Array<String>] filtered list of file paths
        #
        def self.group_filter_paths(paths, groups)
          # filter depend on group
          groups = Array(groups)

          if groups.empty?
            paths
          else
            valid_extensions = groups.map do |group|
              GROUP_EXTENSIONS.fetch(group) { raise ::StandardError, "Unknown file group #{group.inspect}" }
            end.flatten

            paths.select do |file_path|
              valid_extensions.include?(::File.extname(file_path))
            end
          end
        end

        # @param [Array<String>] paths  list of file paths
        # @param [String] context_path
        #
        # @return [Array<String>] mapped list of file paths
        #
        def self.relative_paths_from(paths, context_path)
          context_pathname = Pathname.new(context_path)
          paths.map do |path|
            Pathname(path.unicode_normalize).relative_path_from(context_pathname).to_s
          end
        end

        private

        # Looks for files at given context path, if there is no file, it will try again with pattern for any extension
        #
        # @param [String] pattern  pattern of the desired files
        # @param [Array<Symbol>] groups  list of group names, nil or empty array for all groups, for valid values see GROUP_EXTENSIONS
        # @param [String] context_path  path for root of searching, it is also defines start folder of relative path
        # @param [String] orig_context_path  original context path, wo it will work nicely with iterative searching
        #
        # @return [Array<String>] list of founded files
        #
        def __find_files(pattern, groups, context_path, orig_context_path = context_path)
          files = __core_find_files(pattern, groups, context_path, orig_context_path)

          # try to find files with any extension
          files = __core_find_files(pattern + '.*', groups, context_path, orig_context_path) if files.empty?

          files
        end

        # Core method for finding files, it only search for files, filter by input groups and map the final paths to pretty relative paths from context_path
        #
        # @param [String] pattern  pattern of the desired files
        # @param [Array<Symbol>] groups  list of group names, nil or empty array for all groups, for valid values see GROUP_EXTENSIONS
        # @param [String] context_path  path for root of searching, it is also defines start folder of relative path
        # @param [String] orig_context_path  original context path, wo it will work nicely with iterative searching
        #
        # @return [Array<String>] list of founded files
        #
        def __core_find_files(pattern, groups, context_path, orig_context_path = context_path)
          context_path = File.file?(context_path) ? File.dirname(context_path) : context_path
          orig_context_path = File.file?(orig_context_path) ? File.dirname(orig_context_path) : orig_context_path

          full_pattern = ::File.expand_path(pattern, context_path)
          file_paths = __core_find_files_from_pattern(full_pattern)

          file_paths.reject! do |path|
            File.directory?(path)
          end

          # remove any files that should be ignored
          file_paths.reject! do |path|
            ignored_patterns.any? { |exclude_pattern| ::File.fnmatch(exclude_pattern, path) }
          end

          file_paths = self.class.group_filter_paths(file_paths, groups)

          # create relative path to context path
          file_paths = self.class.relative_paths_from(file_paths, orig_context_path)

          file_paths
        end

        def __core_find_files_from_pattern(pattern)
          raise 'Implement this in subclass'
        end
      end
    end
  end
end
