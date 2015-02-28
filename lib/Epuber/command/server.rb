# encoding: utf-8

require_relative '../command'

module Epuber
  class Command
    class Server < Command
      self.summary = 'Starts web server to display and debug e-book pages.'
      self.arguments = [
        CLAide::Argument.new('TARGET', false, false),
      ]

      def initialize(args)
        super
        @selected_target_name = args.shift_argument
      end

      def validate!
        super
        verify_one_bookspec_exists!
      end

      def run
        require_relative '../server'

        target = if @selected_target_name.nil?
                   book.targets.first
                 else
                   book.target_named(@selected_target_name)
                 end

        help!('Not existing target') if target.nil?

        Epuber::Server.run!(book, target)
      end
    end
  end
end
