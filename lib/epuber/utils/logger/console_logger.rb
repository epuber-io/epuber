# frozen_string_literal: true

require_relative 'abstract_logger'

module Epuber
  module Logger
    class ConsoleLogger < AbstractLogger
      def _log(level, message, location: nil, backtrace: nil, sticky: false)
        prev_line = _remove_sticky_message

        # save sticky message
        @sticky_message = message if sticky

        formatted_message = _format_message(level, message, location: location, backtrace: backtrace)

        # print the message
        if sticky
          $stdout.print(formatted_message)
        else
          $stdout.puts(formatted_message)

          # reprint previous sticky message when this message is not sticky
          if prev_line
            @sticky_message = prev_line
            $stdout.print(prev_line)
          end
        end
      end

      private

      # @param [Symbol] level color of the output
      #
      # @return [Symbol] color
      #
      def _color_from_level(level)
        case level
        when :error then   :red
        when :warning then :yellow
        when :info then    :white
        when :debug then   :blue
        else
          raise "Unknown output level #{level}"
        end
      end

      # @param [Symbol] level color of the output
      # @param [String] message message of the error
      # @param [Thread::Backtrace::Location] location location of the error
      #
      # @return [String] formatted message
      #
      def _format_message(level, message, location: nil, backtrace: nil)
        location = _location_from_obj(location)

        comps = []
        comps << message.to_s
        message_already_formatted =
          message.is_a?(Epuber::Compiler::Problem) || message.is_a?(Epuber::Checker::TextChecker::MatchProblem)

        should_add_location = if message_already_formatted || location.nil?
                                false
                              else
                                %i[error warning].include?(level)
                              end

        # add location
        if should_add_location
          path = location.path

          # calculate relative path when path is absolute and in project
          path = path[(Config.instance.project_path.size + 1)..] if path.start_with?(Config.instance.project_path)

          line_parts = [
            "  (in file #{path}",
          ]
          line_parts << "line #{location.lineno}" if location.lineno
          line_parts << "column #{location.column}" if location.column

          comps << "#{line_parts.join(' ')})"
        end

        # add backtrace
        comps += _format_backtrace(backtrace, location: location) if backtrace && @verbose && level == :error

        comps.join("\n").ansi.send(_color_from_level(level))
      end

      # @param [Array<Thread::Backtrace::Location>] locations locations of the error (only for verbose output)
      # @param [Thread::Backtrace::Location] location location of the error
      #
      # @return [Array<String>] formatted message
      #
      def _format_backtrace(locations, location: nil)
        index = locations.index(location) || 0

        formatted = []
        formatted << '' # empty line
        formatted << 'Full backtrace:'
        formatted += locations[index, locations.size].map do |loc|
          "  #{loc}"
        end

        formatted
      end

      # @return [String, nil] last line
      #
      def _remove_sticky_message
        last_line = @sticky_message

        unless @sticky_message.nil?
          $stdout.print("\033[2K") # remove line, but without moving cursor
          $stdout.print("\r") # go to beginning of line
          @sticky_message = nil
        end

        last_line
      end
    end
  end
end
