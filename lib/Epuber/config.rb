# encoding: utf-8

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
      @bookspec_path ||= Dir.glob('*.bookspec').first
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
