# encoding: utf-8

require 'unicode_normalize'


module Epuber
  class Compiler
    module FileFinders
      require_relative 'abstract'

      class Imaginary < Abstract
        class DirEntry
          # @return [Hash<String, String | DirEntry>]
          #
          attr_accessor :entries

          attr_reader :name

          def initialize(name)
            @name    = name
            @entries = {}
          end

          def [](key)
            @entries[key]
          end

          def []=(key, value)
            @entries[key] = value
          end

          def ==(other)
            name == other.name && entries == other.entries
          end
        end

        class FileEntry
          attr_reader :name

          attr_reader :absolute_path

          def initialize(name, absolute_path)
            @name          = name
            @absolute_path = absolute_path
          end

          def ==(other)
            other.is_a?(FileEntry) ? name == other.name : name == other.to_s
          end
        end

        # @return [DirEntry]
        #
        attr_reader :root

        def initialize(source_path)
          super
          @root = DirEntry.new('/')

          make_dir_p(File.expand_path(source_path))
        end

        # @param [String | Array<String>] path  path to folder to create
        #
        # @return [DirEntry] dir entry for given path
        #
        def make_dir_p(path)
          components = path.is_a?(Array) ? path : self.class.path_parts(path)

          current = root
          components.each do |dir|
            entry        = current[dir]
            current[dir] = entry = DirEntry.new(dir) if entry.nil?
            current      = entry
          end

          current
        end

        # @param
        def add_file(file_path)
          file_path = File.expand_path(file_path, source_path)

          *path, file_name = self.class.path_parts(file_path)

          make_dir_p(path)[file_name] = FileEntry.new(file_name, file_path)
        end


        def __core_find_files_from_pattern(pattern)
          parts = self.class.path_parts(pattern)
          find_recurser(root, parts).flatten.map do |item|
            item.absolute_path
          end
        end

        private

        def self.path_parts(path)
          path.split(File::SEPARATOR).reject(&:empty?)
        end

        def find_recurser(dir, parts)
          return [] unless dir.respond_to? :[]

          pattern, *parts = parts
          matches         = case pattern
                              when '**'
                                case parts
                                  when ['*']
                                    parts = [] # end recursion
                                    directories_under(dir).map do |d|
                                      d.entries.select do |f|
                                        (f.is_a?(FileEntry) || f.is_a?(DirEntry)) &&
                                          f.name.match(/\A(?!\.)/)
                                      end
                                    end.flatten.uniq
                                  when []
                                    parts = [] # end recursion
                                    dir.entries.flatten.uniq
                                  else
                                    directories_under(dir)
                                end
                              else
                                regex_body = pattern.gsub('.', '\.')
                                               .gsub('?', '.')
                                               .gsub('*', '.*')
                                               .gsub('(', '\(')
                                               .gsub(')', '\)')
                                               .gsub(/\{(.*?)\}/) do
                                  "(#{Regexp.last_match[1].gsub(',', '|')})"
                                end
                                               .gsub(/\A\./, '(?!\.).')
                                dir.entries.reject { |k, _v| /\A#{regex_body}\Z/ !~ k }.values
                            end

          if parts.empty? # we're done recursing
            matches
          else
            matches.map { |entry| find_recurser(entry, parts) }
          end
        end

        # @param [DirEntry] dir
        #
        # @return [Hash<String, DirEntry>]
        #
        def directories_under(dir)
          children = dir.entries.values.select { |f| f.is_a?(DirEntry) }
          (Array(dir) + children + children.map { |c| directories_under(c) }).flatten.uniq
        end
      end
    end
  end
end

