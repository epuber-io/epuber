# encoding: utf-8

require 'pathname'
require_relative 'lockfile'


module Epuber
  class Config
    WORKING_PATH = '.epuber'

    # @return [String]
    #
    def project_path
      @project_path ||= Dir.pwd.unicode_normalize
    end

    # @param of_file [String] absolute path to file
    #
    # @return [String] relative path to file from root of project
    #
    def pretty_path_from_project(of_file)
      Pathname.new(of_file.unicode_normalize).relative_path_from(Pathname.new(project_path))
    end

    # @return [String]
    #
    def working_path
      @working_path ||= File.join(project_path, WORKING_PATH)
    end

    # @return [String]
    #
    def bookspec_path
      @bookspec_path ||= find_all_bookspecs.first
    end

    # @return [String]
    #
    def bookspec_lockfile_path
      "#{bookspec_path}.lock"
    end

    # @return [Array<String>]
    #
    def find_all_bookspecs
      Dir.chdir(project_path) do
        Dir.glob('*.bookspec').map do |path|
          File.expand_path(path)
        end
      end
    end

    # @return [Epuber::Book]
    #
    def bookspec
      require_relative 'book'
      @bookspec ||= (
        book = Epuber::Book.from_file(bookspec_path)
        book.finish_toc
        book.validate
        book.freeze
        book
      )
    end

    # @param [Epuber::Book] bookspec
    #
    # @return [Epuber::Book]
    #
    def bookspec=(bookspec)
      @bookspec = bookspec
    end

    # @return [Epuber::Lockfile]
    #
    def bookspec_lockfile
      @bookspec_lockfile ||= (
        lockfile = Lockfile.from_file(bookspec_lockfile_path)
        lockfile.version = Epuber::VERSION
        lockfile
      )
    end

    # @return nil
    #
    def save_lockfile
      bookspec_lockfile.write_to_file
    end

    # @param target [Epuber::Book::Target]
    #
    # @return [String]
    #
    def build_path(target)
      File.join(working_path, 'build', target.name.to_s)
    end

    # @param target [Epuber::Book::Target]
    #
    # @return [String]
    #
    def release_build_path(target)
      File.join(working_path, 'release_build', target.name.to_s)
    end

    # ---------------------------------------------------------------------------------------------------------------- #

    # Singleton
    #
    # @return [Epuber::Config]
    #
    def self.instance
      @instance ||= new
    end

    class << self
      attr_accessor :test

      def test?
        test
      end
    end

    self.test = false
  end
end

# HACK: this should be done with nicer way
#
at_exit do
  unless Epuber::Config.test?
    Epuber::Config.instance.save_lockfile
  end
end
