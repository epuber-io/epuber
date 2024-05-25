# frozen_string_literal: true

require 'open3'

module Epuber
  class Epubcheck
    Problem = Struct.new(:level, :code, :location, :message, keyword_init: true) do
      # !attribute [r] level
      #   @return [Symbol] level of the problem (:fatal, :error, :warning, :info, :usage, :suppressed)

      # !attribute [r] code
      #   @return [String] code of the problem (for example: RSC-005)

      # !attribute [r] location
      #   @return [Epuber::Location] location of the problem

      # !attribute [r] message
      #   @return [String] message of the problem

      def to_s
        "#{level}(#{code}): #{location.path}(#{location.lineno},#{location.column}): #{message}"
      end

      def error?
        level == :error || level == :fatal
      end
    end

    class << self
      LINE_REGEXP = /(?<level>[A-Z]+)\((?<code>[A-Z\-0-9]+)\):\s*(?<path>.+?)\((?<lineno>[0-9]+),(?<column>[0-9]+)\):\s*(?<message>[^\n]+)/.freeze # rubocop:disable Layout/LineLength

      # @param [String] path path to file
      #
      # @return [Array<Problem>] list of problems
      #
      def check(path)
        problems = []
        Open3.popen3('epubcheck', path) do |_stdin, stdout, stderr, _wait_thr|
          problems += _process_output(stdout)
          problems += _process_output(stderr)
        end

        problems
      end

      # @param [StringIO] output
      #
      # @return [Array<Problem, String>]
      #
      def _process_output(output)
        problems = []
        output.each_line do |line|
          line = _parse_line(line.chomp)
          if line.is_a?(Problem)
            UI.debug(line.to_s)
            problems << line
          else
            UI.debug(line)
          end
        end

        problems
      end

      # @param [String] line
      #
      # @return [Problem, String]
      #
      def _parse_line(line)
        match = LINE_REGEXP.match(line)
        return line unless match

        location = Epuber::Location.new(path: match[:path], lineno: match[:lineno].to_i, column: match[:column].to_i)

        Problem.new(
          level: match[:level].downcase.to_sym,
          code: match[:code],
          location: location,
          message: match[:message],
        )
      end
    end
  end
end
