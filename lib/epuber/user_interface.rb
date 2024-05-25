# frozen_string_literal: true

require 'active_support/core_ext/object/try'
require 'nokogiri'
require 'delegate'

require_relative 'ruby_extensions/thread'
require_relative 'command'
require_relative 'utils/location'
require_relative 'utils/logger/console_logger'

module Epuber
  class UserInterface < Delegator
    # @return [Logger::AbstractLogger]
    #
    attr_reader :logger

    def initialize
      super(nil)

      @logger = Logger::ConsoleLogger.new
    end

    def __getobj__
      @logger
    end

    def __setobj__(obj)
      @logger = obj
    end
  end

  # shortcut
  UI = UserInterface.new
end
