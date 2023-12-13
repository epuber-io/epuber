# frozen_string_literal: true

require 'zip'

require_relative '../command'
require_relative '../from_file/bookspec_generator'

module Epuber
  class Command
    class FromFile < Command
      self.summary = 'Initialize current folder to use it as Epuber project from existing EPUB file'
      self.arguments = [
        CLAide::Argument.new('EPUB_FILE', true),
      ]

      # @param argv [CLAide::ARGV]
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

        Zip::File.open(@filepath) do |zip_file|
          @zip_file = zip_file

          validate_mimetype

          opf_path = content_opf_path
          @opf = Nokogiri::XML(zip_file.read(opf_path))

          UI.puts generate_bookspec
        end
      end
    end

    private

    # @param zip_file [Zip::File]
    #
    # @return [void]
    #
    def validate_mimetype
      entry = @zip_file.find_entry('mimetype')
      UI.error! 'This is not valid EPUB file (mimetype file is missing)' if entry.nil?

      mimetype = @zip_file.read('mimetype')

      return if mimetype == 'application/epub+zip'

      UI.error! <<~MSG
        This is not valid EPUB file (mimetype file does not contain required application/epub+zip, it is #{mimetype} instead)
      MSG
    end

    # @param zip_file [Zip::File]
    #
    # @return [String]
    def content_opf_path
      entry = @zip_file.find_entry('META-INF/container.xml')
      UI.error! 'This is not valid EPUB file (META-INF/container.xml file is missing)' if entry.nil?

      doc = Nokogiri::XML(@zip_file.read(entry))
      doc.remove_namespaces!

      rootfile = doc.at_xpath('//rootfile')
      if rootfile.nil?
        UI.error! 'This is not valid EPUB file (META-INF/container.xml file does not contain any <rootfile> element)'
      end

      rootfile['full-path']
    end

    # @param opf [Nokogiri::XML::Document]
    # @param zip_file [Zip::File]
    #
    # @return [String]
    def generate_bookspec
      BookspecGenerator.new(@opf).generate_bookspec
    end
  end
end
