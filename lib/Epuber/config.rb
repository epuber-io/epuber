# encoding: utf-8

require_relative 'lockfile'


module Epuber
  class Config
    WORKING_PATH = '.epuber'

    # @return [String]
    #
    def project_path
      @project_path ||= Dir.pwd
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

    # @return [Epuber::Book::Book]
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

    # @return [Epuber::Lockfile]
    #
    def bookspec_lockfile
      @bookspec_lockfile ||= (
        lockfile = Lockfile.from_file(bookspec_lockfile_path)
        lockfile.version = Epuber::VERSION
        lockfile
      )
    end

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

    # ---------------------------------------------------------------------------------------------------------------- #

    # Singleton
    #
    # @return [Epuber::Config]
    #
    def self.instance
      @instance ||= new
    end
  end
end


at_exit do
  puts 'DEBUG: Saving lockfile'
  Epuber::Config.instance.save_lockfile
end
