# frozen_string_literal: true

module Epuber
  module Logger
    class AbstractLogger
      LEVELS = %i[
        error
        warning
        info
        debug
      ].freeze

      # @param [Hash] opts
      # @option opts [Boolean] :verbose (false)
      # @option opts [Boolean] :debug_steps_times (false)
      #
      def initialize(opts = {})
        @verbose = opts.fetch(:verbose, false)
        @debug_steps_times = opts.fetch(:debug_steps_times, false)

        @current_file = nil
        @sticky_message = nil
      end

      # Report error message
      #
      # @param [String, #to_s] message
      # @param [Thread::Backtrace::Location, Epuber::Location, Nokogiri::XML::Node, nil] location
      # @param [Boolean] stick if true, the error message will be sticked to the previous one
      #
      def error!(message, location: caller_locations.first)
        _common_log(:error, message, location: location)
        raise Epuber::PlainInformative, message
      end

      # Report error message
      #
      # @param [String, #to_s] message
      # @param [Thread::Backtrace::Location, Epuber::Location, Nokogiri::XML::Node, nil] location
      # @param [Boolean] stick if true, the error message will be sticked to the previous one
      #
      def error(message, sticky: false, location: caller_locations.first)
        _common_log(:error, message, sticky: sticky, location: location)
      end

      # Report warning message
      #
      # @param [String, #to_s] message
      # @param [Thread::Backtrace::Location, Epuber::Location, Nokogiri::XML::Node, nil] location
      #
      def warning(message, sticky: false, location: caller_locations.first)
        _common_log(:warning, message, sticky: sticky, location: location)
      end

      # Report info message
      #
      # @param [String, #to_s] message
      # @param [Thread::Backtrace::Location, Epuber::Location, Nokogiri::XML::Node, nil] location
      #
      def info(message, sticky: false, location: caller_locations.first)
        _common_log(:info, message, sticky: sticky, location: location)
      end

      # Report debug message
      #
      # @param [String, #to_s] message
      # @param [Thread::Backtrace::Location, Epuber::Location, Nokogiri::XML::Node, nil] location
      #
      def debug(message, sticky: false, location: caller_locations.first)
        _common_log(:debug, message, sticky: sticky, location: location)
      end

      # @param [Epuber::Compiler::FileTypes::AbstractFile] file
      # @param [Fixnum] index
      # @param [Fixnum] count
      #
      def start_processing_file(file, index, count)
        @current_file = file

        _common_log(:debug, "▸ Processing #{file.source_path} (#{index + 1} of #{count})", sticky: true)
      end

      def end_processing
        _remove_sticky_message
        @current_file = nil
      end

      # @param [String] info_text
      #
      def print_processing_debug_info(info_text)
        return unless @verbose

        message = if @current_file.nil?
                    "▸ #{info_text}"
                  else
                    "▸ #{@current_file.source_path}: #{info_text}"
                  end
        _log(:debug, message)
      end

      # @param [String] step_name
      # @param [Fixnum] time
      #
      def print_step_processing_time(step_name, time = nil)
        return yield unless @debug_steps_times

        _remove_sticky_message

        if block_given?
          start = Time.now
          returned_value = yield

          time = Time.now - start
        end

        info_text = "Step #{step_name} took #{time * 1000} ms"
        message = if @current_file.nil?
                    "▸ #{info_text}"
                  else
                    "▸ #{@current_file.source_path}: #{info_text}"
                  end

        $stdout.puts(_format_message(:debug, message))

        returned_value
      end

      protected

      # Point of implementation for concrete logger
      #
      # @param [Symbol] level
      # @param [String] message
      # @param [Epuber::Location, nil] location
      # @param [Array<Thread::Backtrace::Location>, nil] backtrace
      # @param [Boolean] remove_last if true, the last line should be removed
      #
      def _log(level, message, location: nil, backtrace: nil, remove_last: false) # rubocop:disable Lint/UnusedMethodArgument
        raise 'Not implemented, this is abstract class'
      end

      # Remove last line of the output (if it was sticky)
      #
      # @return [String, nil] last line
      #
      def _remove_sticky_message; end

      private

      # Core logging method
      #
      # @param level [Symbol]
      # @param message [String]
      # @param location [Thread::Backtrace::Location, Epuber::Location, Nokogiri::XML::Node,
      #                  Epuber::Compiler::FileTypes::AbstractFile, nil]
      # @param sticky [Symbol, nil] if true, the message will be sticky (will be always as the last message)
      #
      def _common_log(level, message, location: nil, sticky: false)
        raise ArgumentError, "Unknown log level #{level}" unless LEVELS.include?(level)

        location = _location_from_obj(location)

        if @verbose && level == :error
          backtrace = location.try(:backtrace_locations) || message.try(:backtrace_locations) || caller_locations
        end

        _log(level, message, location: location, backtrace: backtrace, sticky: sticky)
      end

      # @param [Thread::Backtrace::Location, Nokogiri::XML::Node] obj
      #
      # @return [Location]
      #
      def _location_from_obj(obj)
        case obj
        when ::Thread::Backtrace::Location
          Location.new(path: obj.path, lineno: obj.lineno)
        when ::Nokogiri::XML::Node
          Location.new(path: obj.document.file_path, lineno: obj.line)
        when Location
          obj
        when Epuber::Compiler::FileTypes::AbstractFile
          Location.new(path: obj.source_path)
        end
      end
    end
  end
end
