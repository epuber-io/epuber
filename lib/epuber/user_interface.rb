
require 'active_support/core_ext/object/try'
require 'nokogiri'

require_relative 'ruby_extensions/thread'
require_relative 'command'


module Epuber
  class UserInterface
    Location = Struct.new(:path, :lineno)

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
    #
    def self.error(message, location: nil)
      puts(_format_message(:error, message, location: location))
      _print_backtrace(message.try(:backtrace_locations) || caller_locations, location: location)
    end

    # @param [String] message message of the error
    # @param [Thread::Backtrace::Location] location location of the error
    #
    def self.warning(message, location: nil)
      puts(_format_message(:warning, message, location: location))
    end

    def self.remove_last_line
      $stdout.print("\b" * (@last_line.length))
    end

    def self.print(message)
      @last_line = message
      $stdout.print(message)
    end

    def self.puts(message)
      $stdout.puts(message)
    end


    # @param [Compiler::FileTypes::AbstractFile] file
    #
    # @return nil
    #
    def self.print_processing_file(file, index, count)
      remove_processing_file_line

      @last_processing_file_line = "▸ Processing #{file.source_path} (#{index + 1} of #{count})"
      $stdout.print(@last_processing_file_line)
    end

    def self.remove_processing_file_line
      unless @last_processing_file_line.nil?
        $stdout.print("\033[2K") # remove line, but without moving cursor
        $stdout.print("\r") # go to beginning of line
        @last_processing_file_line = nil
      end
    end

    def self.processing_files_done
      remove_processing_file_line
    end

    private

    # @param [Symbol] level color of the output
    #
    # @return [Symbol] color
    #
    def self._color_from_level(level)
      case level
        when :error;   :red
        when :warning; :yellow
        when :normal;  :normal
        when :debug;   :gray
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
        Location.new(obj.path, obj.lineno)
      when ::Nokogiri::XML::Node
        Location.new(obj.document.file_path, obj.line)
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
      comps << "  (in file #{location.path} line #{location.lineno}" unless location.nil?

      comps.join("\n").ansi.send(_color_from_level(level))
    end

    # @param [Array<Thread::Backtrace::Location>] locations locations of the error (only for verbose output)
    # @param [Thread::Backtrace::Location] location location of the error
    #
    # @return [String] formatted message
    #
    def self._format_backtrace(locations, location: nil)
      index = locations.index(location) || 0
      locations[index, locations.size].map { |loc| loc.to_s }
    end

    # @param [Thread::Backtrace::Location] location location of the error
    #
    def self._print_backtrace(locations, location: nil)
      puts(_format_backtrace(locations, location: location)) if current_command.verbose?
    end
  end

  # shortcut
  UI = UserInterface
end
