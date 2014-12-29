
require 'claide'

module Epuber
  class Command < CLAide::Command
    require_relative 'command/compile'
    require_relative 'command/init'

    self.abstract_command = true
    self.command = 'epuber'
    self.version = VERSION
    self.description = 'Epuber, easy creating and maintaining e-book.'
    self.plugin_prefixes = self.plugin_prefixes + %w(epuber)

    def run
      puts "Running command with class #{self.class}"
    end
  end
end
