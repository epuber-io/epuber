# frozen_string_literal: true

require 'active_support/core_ext/object/try'
require 'nokogiri'

require_relative 'ruby_extensions/thread'
require_relative 'command'

module Epuber
  class UserInterface
    Location = Struct.new(:path, :lineno, :column, keyword_init: true)

    class << self
      # @return [Epuber::Command]
      #
      attr_accessor :current_command
    end

    # Fatal error, prints message and exit with return code 1
    #
    # @param [Exception, String] message message of the error
    # @param [Thread::Backtrace::Location] location location of the error
    #
    def self.error!(message, location: nil)
      error(message, location: location)
      exit(1)
    end

    # Fatal error, prints message and exit with return code 1
    #
    # @param [String] message message of the error
    # @param [Thread::Backtrace::Location] location location of the error
    # @param [Bool] backtrace  output backtrace locations, nil == automatic, true == always and false == never
    #
    def self.error(message, location: nil)
      _clear_processing_line_for_new_output do
        $stdout.puts(_format_message(:error, message, location: location))
        if current_command&.verbose?
          _print_backtrace(location.try(:backtrace_locations) || message.try(:backtrace_locations) || caller_locations,
                           location: location)
        end
      end
    end

    # @param [String] message message of the error
    # @param [Thread::Backtrace::Location] location location of the error
    #
    def self.warning(message, location: nil)
      _clear_processing_line_for_new_output do
        $stdout.puts(_format_message(:warning, message, location: location))
      end
    end

    # @param [#to_s] problem some problem, object just have to know to convert self into string with method #to_s
    #
    def self.print_processing_problem(problem)
      _clear_processing_line_for_new_output do
        $stdout.puts(problem.to_s.ansi.send(_color_from_level(:warning)))
      end
    end

    # @param [String] info_text
    #
    def self.print_processing_debug_info(info_text)
      return unless current_command&.verbose?

      _clear_processing_line_for_new_output do
        message = if @current_file.nil?
                    "▸ #{info_text}"
                  else
                    "▸ #{@current_file.source_path}: #{info_text}"
                  end

        $stdout.puts(message.ansi.send(_color_from_level(:debug)))
      end
    end

    # @param [Compiler::FileTypes::AbstractFile] file
    #
    # @return nil
    #
    def self.print_processing_file(file, index, count)
      remove_processing_file_line

      @current_file = file

      @last_processing_file_line = "▸ Processing #{file.source_path} (#{index + 1} of #{count})"
      $stdout.print(@last_processing_file_line)
    end

    def self.remove_processing_file_line
      last_line = @last_processing_file_line

      unless @last_processing_file_line.nil?
        $stdout.print("\033[2K") # remove line, but without moving cursor
        $stdout.print("\r") # go to beginning of line
        @last_processing_file_line = nil
      end

      last_line
    end

    def self.processing_files_done
      remove_processing_file_line

      @current_file = nil
    end

    def self.puts(message)
      _clear_processing_line_for_new_output do
        $stdout.puts(message)
      end
    end

    # @param [Compiler::FileTypes::AbstractFile] file
    # @param [String] step_name
    # @param [Fixnum] time
    #
    def self.print_step_processing_time(step_name, time = nil)
      return yield if !current_command || !current_command.debug_steps_times

      remove_processing_file_line

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

    def self._clear_processing_line_for_new_output
      last_line = remove_processing_file_line

      yield

      @last_processing_file_line = last_line
      $stdout.print(last_line)
    end

    # @param [Symbol] level color of the output
    #
    # @return [Symbol] color
    #
    def self._color_from_level(level)
      case level
      when :error then   :red
      when :warning then :yellow
      when :normal then  :white
      when :debug then   :blue
      else
        raise "Unknown output level #{level}"
      end
    end

    # @param [Thread::Backtrace::Location, Nokogiri::XML::Node] obj
    #
    # @return [Location]
    #
    def self._location_from_obj(obj)
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

    # @param [Symbol] level color of the output
    # @param [String] message message of the error
    # @param [Thread::Backtrace::Location] location location of the error
    #
    # @return [String] formatted message
    #
    def self._format_message(level, message, location: nil)
      location = _location_from_obj(location)

      comps = []
      comps << message.to_s
      message_already_formatted =
        message.is_a?(Epuber::Compiler::Problem) || message.is_a?(Epuber::Checker::TextChecker::MatchProblem)

      if !location.nil? && !message_already_formatted
        path = location.path

        # calculate relative path when path is absolute and in project
        path = path[Config.instance.project_path.size + 1..-1] if path.start_with?(Config.instance.project_path)

        line_parts = [
          "  (in file #{path}",
        ]
        line_parts << "line #{location.lineno}" if location.lineno
        line_parts << "column #{location.column}" if location.column

        comps << "#{line_parts.join(' ')})"
      end

      comps.join("\n").ansi.send(_color_from_level(level))
    end

    # @param [Array<Thread::Backtrace::Location>] locations locations of the error (only for verbose output)
    # @param [Thread::Backtrace::Location] location location of the error
    #
    # @return [String] formatted message
    #
    def self._format_backtrace(locations, location: nil)
      index = locations.index(location) || 0
      locations[index, locations.size].map(&:to_s)
    end

    # @param [Thread::Backtrace::Location] location location of the error
    #
    def self._print_backtrace(locations, location: nil)
      $stdout.puts(_format_backtrace(locations, location: location)) if current_command.verbose?
    end
  end

  # shortcut
  UI = UserInterface
end
