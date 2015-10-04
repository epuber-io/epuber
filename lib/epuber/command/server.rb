# encoding: utf-8

require_relative '../command'
require 'os'


module Epuber
  class Command
    class Server < Command
      self.summary = 'Starts web server to display and debug e-book pages.'
      self.arguments = [
        CLAide::Argument.new('TARGET', false, false),
      ]

      def self.options
        [
          ['--open',   'Opens the web page in default web browser, working only on OS X'],
        ].concat(super)
      end

      # @param args [CLAide::ARGV]
      #
      def initialize(args)
        super
        @selected_target_name = args.shift_argument
        @open_web_browser = args.flag?('open', false)
      end

      def validate!
        super
        verify_one_bookspec_exists!
      end

      def run
        super

        require_relative '../server'

        target = if @selected_target_name.nil?
                   book.targets.first
                 else
                   book.target_named(@selected_target_name)
                 end

        help!('Not existing target') if target.nil?

        Epuber::Server.run!(book, target, verbose: verbose?) do |uri|
          if OS.osx?
            if @open_web_browser
              system "open #{uri}"
            else
              puts 'Web browser can be automatically opened by adding --open flag, see --help'
            end
          end
        end
      end
    end
  end
end
