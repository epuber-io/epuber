# frozen_string_literal: true

require_relative '../command'
require_relative '../from_file/from_file_executor'

module Epuber
  class Command
    class FromFile < Command
      self.summary = 'Initialize current folder to use it as Epuber project from existing EPUB file'
      self.arguments = [
        CLAide::Argument.new('EPUB_FILE', true),
      ]

      # @param [CLAide::ARGV] argv
      #
      def initialize(argv)
        @filepath = argv.arguments!.first

        super(argv)
      end

      def validate!
        super

        help! 'You must specify path to existing EPUB file' if @filepath.nil?
        help! "File #{@filepath} doesn't exists" unless File.exist?(@filepath)

        existing = Dir.glob('*.bookspec')
        help! "Can't reinit this folder, #{existing.first} already exists." unless existing.empty?
      end

      def run
        super

        FromFileExecutor.new(@filepath).run
      end
    end
  end
end
