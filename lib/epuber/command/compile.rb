# encoding: utf-8

require_relative 'build'

module Epuber
  class Command
    class Compile < Build
      self.summary = '[Deprecated] Compile targets into multiple EPUB files. Use `build` instead.'
      Command.inherited(self)

      def initialize(argv)
        UI.warning('Compile command is now deprecated, please use `build` command instead.')

        super
      end
    end
  end
end
