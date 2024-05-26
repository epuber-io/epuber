# frozen_string_literal: true

require 'delegate'

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
