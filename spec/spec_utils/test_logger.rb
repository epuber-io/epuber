# frozen_string_literal: true

require_relative '../../lib/epuber/utils/logger/abstract_logger'

class TestLogger < Epuber::Logger::AbstractLogger
  Message = Struct.new(:level, :message, :location, :sticky, keyword_init: true) do
    def to_s
      text = message.to_s

      CLAide::ANSI::COLORS.each_key do |key|
        text = text.gsub(CLAide::ANSI::Graphics.foreground_color(key), "<#{key}:start>")
      end

      text.gsub(CLAide::ANSI::DEFAULT_FOREGROUND_COLOR, '<color-end>')
    end
  end

  # @return [Array<Message>]
  #
  attr_reader :messages

  def initialize(opts = {})
    super

    @messages = []
  end

  # Return so far messages formatted as string
  #
  # @return [String]
  #
  def formatted_messages
    @messages
      .map(&:to_s)
      .join("\n")
  end

  ## Overriden methods

  def _log(level, message, location: nil, backtrace: nil, sticky: false) # rubocop:disable Lint/UnusedMethodArgument
    @messages << Message.new(level: level, message: message, location: location, sticky: sticky)
  end

  def _remove_sticky_message
    @messages.pop if @messages.last&.sticky
  end
end
