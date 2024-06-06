# frozen_string_literal: true

require 'open3'
require 'json'

require_relative 'utils/location'

module Epuber
  class Epubcheck
    Report = Struct.new(:problems, keyword_init: true) do
      # !attribute [r] problems
      #   @return [Array<Problem>] problems found by epubcheck

      def error?
        problems.any?(&:error?)
      end
    end

    Problem = Struct.new(:level, :code, :location, :message, keyword_init: true) do
      # !attribute [r] level
      #   @return [Symbol] level of the problem (:fatal, :error, :warning, :info, :usage, :suppressed)

      # !attribute [r] code
      #   @return [String] code of the problem (for example: RSC-005)

      # !attribute [r] location
      #   @return [Epuber::Location, nil] location of the problem

      # !attribute [r] message
      #   @return [String] message of the problem

      def to_s
        "#{level}(#{code}): #{location.path}(#{location.lineno},#{location.column}): #{message}"
      end

      def error?
        level == :error || level == :fatal
      end

      def self.from_json(json)
        json_location = json['locations'].first

        location = if json_location
                     Epuber::Location.new(
                       path: json_location['path'],
                       lineno: json_location['line'],
                       column: json_location['column'],
                     )
                   end

        new(
          level: json['severity'].downcase.to_sym,
          code: json['ID'],
          message: json['message'],
          location: location,
        )
      end
    end

    class << self
      # @param [String] path path to file
      #
      # @return [Report] report of the epubcheck
      #
      def check(path)
        report = nil

        Dir.mktmpdir('epubcheck-') do |tmpdir|
          json_path = File.join(tmpdir, 'epubcheck.json')
          Open3.popen2('epubcheck', path, '--json', json_path) do |_stdin, _stdout, wait_thr|
            wait_thr.value # wait for the process to finish
            report = _parse_json(File.read(json_path))
          end
        end

        report
      end

      # @param [String] string json string
      # @return [Report]
      #
      def _parse_json(string)
        json = JSON.parse(string)
        messages = json['messages']

        Report.new(problems: messages.map { |msg| Problem.from_json(msg) })
      end
    end
  end
end
