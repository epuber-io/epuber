# frozen_string_literal: true

require 'zip'

require_relative 'opf_file'
require_relative 'nav_file'
require_relative 'encryption_handler'

module Epuber
  class FromFileExecutor
    def initialize(filepath)
      @filepath = filepath
    end

    def run
      Zip::File.open(@filepath) do |zip_file|
        @zip_file = zip_file

        validate_mimetype

        @opf_path = content_opf_path
        @opf = OpfFile.new(zip_file.read(@opf_path))

        basename = File.basename(@filepath, File.extname(@filepath))
        File.write("#{basename}.bookspec", generate_bookspec)

        export_files
      end
    end

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
      nav_node, nav_mode = @opf.find_nav
      if nav_node
        nav_path = Pathname.new(@opf_path)
                           .dirname
                           .join(nav_node.href)
                           .to_s
        nav = NavFile.new(@zip_file.read(nav_path), nav_mode)
      end

      BookspecGenerator.new(@opf, nav).generate_bookspec
    end

    def export_files
      encryption_items = prepare_encryption_items

      @opf.manifest_items.each_value do |item|
        # ignore text files which are not in spine
        text_file_extensions = %w[.xhtml .html]
        extension = File.extname(item.href).downcase
        if text_file_extensions.include?(extension) &&
           @opf.spine_items.none? { |spine_item| spine_item.idref == item.id }
          next
        end

        # ignore ncx file
        next if item.media_type == 'application/x-dtbncx+xml'

        full_path = Pathname.new(@opf_path)
                            .dirname
                            .join(item.href)
                            .to_s

        encryption_item = encryption_items&.find { |e| e.file_path == full_path }

        contents = @zip_file.read(full_path)
        if encryption_item
          contents = EncryptionHandler.decrypt_font_data(encryption_item.key, contents, encryption_item.algorithm)
        end

        FileUtils.mkdir_p(File.dirname(item.href))
        File.write(item.href, contents)
      end
    end

    # @return [Array<EncryptionHandler::EncryptionItem>, nil]
    #
    def prepare_encryption_items
      encryption_file_entry = @zip_file.find_entry('META-INF/encryption.xml')
      return unless encryption_file_entry

      idpf_key = EncryptionHandler.parse_idpf_key(@opf.raw_unique_identifier)
      adobe_key = EncryptionHandler.find_and_parse_encryption_key(@opf.identifiers)

      encryption_items = EncryptionHandler.parse_encryption_file(@zip_file.read(encryption_file_entry))
      encryption_items.each do |i|
        if i.algorithm == EncryptionHandler::IDPF_OBFUSCATION
          i.key = idpf_key
        elsif i.algorithm == EncryptionHandler::ADOBE_OBFUSCATION
          i.key = adobe_key
        end
      end

      encryption_items
    end
  end
end
