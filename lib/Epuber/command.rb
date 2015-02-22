# encoding: utf-8

require 'claide'

module Epuber
  class PlainInformative < StandardError
    include CLAide::InformativeError

    def message
      "[!] #{super}".red
    end
  end

  class Command < CLAide::Command
    require_relative 'command/compile'
    require_relative 'command/init'
    require_relative 'command/server'

    self.abstract_command = true
    self.command = 'epuber'
    self.version = VERSION
    self.description = 'Epuber, easy creating and maintaining e-book.'
    self.plugin_prefixes = plugin_prefixes + %w(epuber)

    def run
      puts "Running command with class #{self.class}"
    end

    protected

    # @return [Epuber::Book::Book]
    #
    def book
      Config.instance.bookspec
    end

    # @return [void]
    #
    # @raise PlainInformative if no .bookspec file don't exists or there are too many
    #
    def verify_one_bookspec_exists!
      bookspec_files = self.class.find_bookspec_files
      raise PlainInformative, "No `.bookspec' found in the project directory." if bookspec_files.empty?
      raise PlainInformative, "Multiple `.bookspec' found in current directory" if bookspec_files.count > 1
    end

    # @return [Array<String>]
    #
    def self.find_bookspec_files
      Dir.glob('*.bookspec')
    end
  end
end
