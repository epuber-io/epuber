require_relative '../command'

module Epuber
  class Command
    class Compile < Command
      self.summary = 'Compile targets into epub.'
      self.arguments = [
        CLAide::Argument.new('TARGETS', false, true)
      ]

      # @param argv [CLAide::ARGV]
      #
      def initialize(argv)
        @targets = argv.arguments!
        super(argv)
      end

      def run
        require_relative '../main_controller'
        MainController.new.compile_targets(@targets)
      end
    end
  end
end
