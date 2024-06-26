# frozen_string_literal: true

require 'pathname'
require 'bade'
require_relative 'lockfile'

module Epuber
  class Config
    WORKING_PATH = '.epuber'

    # @return [String] path to project directory (where .bookspec file is located or current directory if not found)
    #
    def project_path
      @project_path ||= begin
        path = self.class.find_project_dir(Dir.pwd) || Dir.pwd
        path.unicode_normalize
      end
    end

    # @param [String] of_file absolute path to file
    #
    # @return [String] relative path to file from root of project
    #
    def pretty_path_from_project(of_file)
      Pathname.new(of_file.unicode_normalize)
              .relative_path_from(Pathname.new(project_path))
              .to_s
    end

    # @return [String]
    #
    def working_path
      @working_path ||= File.join(project_path, WORKING_PATH)
    end

    # @return [String]
    #
    def bookspec_path
      @bookspec_path ||= self.class.find_bookspec_files(project_path).first
    end

    # @return [String]
    #
    def bookspec_lockfile_path
      "#{bookspec_path}.lock"
    end

    # @return [Epuber::Book]
    #
    def bookspec
      @bookspec ||= self.class.load_bookspec(bookspec_path)
    end

    # @param [Epuber::Book] bookspec
    #
    # @return [Epuber::Book]
    #
    attr_writer :bookspec

    # @return [Boolean]
    #
    attr_accessor :release_build

    # @return [Epuber::Lockfile]
    #
    def bookspec_lockfile
      @bookspec_lockfile ||= Lockfile.from_file(bookspec_lockfile_path) do |lockfile|
        lockfile.epuber_version = Epuber::VERSION
        lockfile.bade_version = Bade::VERSION
      end
    end

    # @return nil
    #
    def save_lockfile
      bookspec_lockfile.epuber_version = Epuber::VERSION
      bookspec_lockfile.bade_version = Bade::VERSION

      bookspec_lockfile.write_to_file
    end

    # @param [Epuber::Book::Target] target
    #
    # @return [String]
    #
    def build_path(target)
      File.join(working_path, 'build', target.name.to_s)
    end

    # @param [Epuber::Book::Target] target
    #
    # @return [String]
    #
    def release_build_path(target)
      File.join(working_path, 'release_build', target.name.to_s)
    end

    # @param [String] cache_name
    #
    # @return [String]
    #
    def build_cache_path(cache_name)
      File.join(working_path, 'build_cache', cache_name)
    end

    # @return [String]
    #
    def file_stat_database_path
      File.join(working_path, 'metadata', 'source_file_stats.yml')
    end

    # @param [Epuber::Book::Target] target
    #
    # @return [String]
    #
    def target_file_stat_database_path(target)
      File.join(working_path, 'metadata', 'target_stats', target.name.to_s, 'file_stats.yml')
    end

    def warn_for_outdated_versions!
      if bookspec_lockfile.epuber_version > Epuber::VERSION
        UI.warning(<<~MSG.rstrip)
          Warning: the running version of Epuber is older than the version that created the lockfile. We suggest you upgrade to the latest version of Epuber by running `gem install epuber`.
        MSG
      end

      return unless bookspec_lockfile.bade_version && bookspec_lockfile.bade_version > Bade::VERSION

      UI.warning(<<~MSG.rstrip)
        Warning: the running version of Bade is older than the version that created the lockfile. We suggest you upgrade to the latest version of Bade by running `gem install bade`.
      MSG
    end

    def same_version_as_last_run?
      !(bookspec_lockfile.epuber_version != Epuber::VERSION ||
          bookspec_lockfile.bade_version.nil? ||
          bookspec_lockfile.bade_version != Bade::VERSION)
    end

    def remove_build_caches
      FileUtils.rm_rf(File.join(working_path, 'build_cache'))
      FileUtils.rm_rf(File.join(working_path, 'build'))
      FileUtils.rm_rf(File.join(working_path, 'metadata'))
    end

    # ---------------------------------------------------------------------------------------------------------------- #

    class << self
      attr_accessor :test

      def test?
        test
      end

      # Singleton
      #
      # @return [Epuber::Config]
      #
      def instance
        @instance ||= new
      end

      def clear_instance!
        @instance = nil
      end

      # @return [Epuber::Book]
      #
      def load_bookspec(path, frozen: true)
        require_relative 'book'

        book = Epuber::Book.from_file(path)
        book.finish_toc
        book.validate

        book.freeze if frozen

        book
      end

      # Find all bookspec files in given directory
      #
      # @param [String] dir
      #
      def find_bookspec_files(dir)
        Dir.chdir(dir) do
          Dir.glob('*.bookspec').map do |path|
            File.expand_path(path)
          end
        end
      end

      # Find project directory by searching for .bookspec files in current and parent directories
      #
      # @param [String] dir
      # @return [String, nil]
      #
      def find_project_dir(dir)
        return dir if find_bookspec_files(dir).any?

        parent = File.dirname(dir)
        return nil if parent == dir

        find_project_dir(parent)
      end
    end

    self.test = false
  end
end
