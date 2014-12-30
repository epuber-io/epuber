
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
    require_relative 'command/check'

    self.abstract_command = true
    self.command = 'epuber'
    self.version = VERSION
    self.description = 'Epuber, easy creating and maintaining e-book.'
    self.plugin_prefixes = self.plugin_prefixes + %w(epuber)

    def run
      puts "Running command with class #{self.class}"
    end

    protected

    def verify_bookspec_exists!
      raise PlainInformative, "No `.bookspec' found in the project directory." if Dir.glob('*.bookspec').empty?
    end
  end
end
