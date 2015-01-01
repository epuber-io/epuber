# encoding: utf-8

require_relative '../command'

module Epuber
  class Command
    class Server < Command
      self.summary = 'Starts web server to display and debug e-book pages.'

      def validate!
        verify_one_bookspec_exists!
      end

      def run
        require_relative '../server'
        Epuber::Server.book = book
        target = book.targets.first
        Epuber::Server.target = target
        Epuber::Server.base_path = File.join(BASE_PATH, 'build', target.name.to_s)
        Epuber::Server.run!
      end
    end
  end
end
