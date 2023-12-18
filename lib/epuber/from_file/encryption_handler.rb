# frozen_string_literal: true

require 'nokogiri'
require 'uuidtools'
require 'digest'

module Epuber
  class EncryptionHandler
    class EncryptionItem
      # Encryption algorithm (probably EncryptionHandler::ADOBE_OBFUSCATION or EncryptionHandler::IDPF_OBFUSCATION)
      #
      # @return [String]
      #
      attr_accessor :algorithm

      # Absolute path to file (from root of EPUB)
      #
      # @return [String]
      #
      attr_accessor :file_path

      # Encryption key for this file
      #
      # @return [String, nil]
      #
      attr_accessor :key

      # @param [String] algorithm
      # @param [String] file_path
      #
      def initialize(algorithm, file_path)
        @algorithm = algorithm
        @file_path = file_path
      end
    end

    ADOBE_OBFUSCATION = 'http://ns.adobe.com/pdf/enc#RC'
    IDPF_OBFUSCATION = 'http://www.idpf.org/2008/embedding'

    # @return [Hash<String, EncryptionItem>] key is abs file path (from root of EPUB), value is EncryptionItem
    #
    attr_reader :encryption_items

    # @param [String] encryption_file contents of META-INF/encryption.xml file
    # @param [Epuber::OpfFile] opf
    #
    def initialize(encryption_file, opf)
      @opf = opf
      @encryption_items = _prepare_items(encryption_file)
    end

    # @param [String] path
    # @param [String] data
    def process_file(path, data)
      enc_item = @encryption_items[path]
      data = EncryptionHandler.decrypt_data(enc_item.key, data, enc_item.algorithm) if enc_item

      data
    end

    # Decrypt data with given key and algorithm
    #
    # @param [String] key
    # @param [String] data
    # @param [String] algorithm
    #
    def self.decrypt_data(key, data, algorithm)
      is_adobe = algorithm == ADOBE_OBFUSCATION
      crypt_len = is_adobe ? 1024 : 1040
      crypt = data.byteslice(0, crypt_len)
                  .bytes
      key_cycle = key.bytes
                     .cycle
      decrypt = crypt.each_with_object([]) { |x, acc| acc << (x ^ key_cycle.next) }
                     .pack('C*')
      decrypt + data.byteslice(crypt_len..-1)
    end

    # Parse IDPF key from unique identifier (main identifier from OPF file)
    #
    # @param [String] raw_unique_identifier
    #
    # @return [String, nil]
    #
    def self.parse_idpf_key(raw_unique_identifier)
      key = raw_unique_identifier.strip.gsub(/[\u0020\u0009\u000d\u000a]/, '')
      Digest::SHA1.digest(key)
    end

    # @param [String] raw_unique_identifier
    # @param [Array<Nokogiri::XML::Node>] identifiers
    #
    # @return [String, nil]
    #
    def self.find_and_parse_encryption_key(identifiers)
      raw_identifier = identifiers.find do |i|
        i['scheme']&.downcase == 'uuid' || i.text.strip.start_with?('urn:uuid:')
      end&.text&.strip
      return nil unless raw_identifier

      uuid_str = raw_identifier.sub(/^urn:uuid:/, '')
      UUIDTools::UUID.parse(uuid_str).raw
    end

    # Parse META-INF/encryption.xml file
    #
    # @return [Array<EncryptionItem>, nil]
    #
    def self.parse_encryption_file(string)
      doc = Nokogiri::XML(string)
      doc.remove_namespaces!

      encryption_node = doc.at_css('encryption')
      return nil unless encryption_node

      encryption_node.css('EncryptedData')
                     .map do |encrypted_data_node|
                       algorithm = encrypted_data_node.at_css('EncryptionMethod')['Algorithm']
                       file_path = encrypted_data_node.at_css('CipherData CipherReference')['URI']

                       EncryptionItem.new(algorithm, file_path)
                     end
    end

    # Prepare encryption items with correct keys
    #
    # @param [String] encryption_file
    #
    # @return [Hash<String, EncryptionItem>]
    #
    def _prepare_items(encryption_file)
      idpf_key = EncryptionHandler.parse_idpf_key(@opf.raw_unique_identifier)
      adobe_key = EncryptionHandler.find_and_parse_encryption_key(@opf.identifiers)

      items = EncryptionHandler.parse_encryption_file(encryption_file)
      items.each do |i|
        if i.algorithm == EncryptionHandler::IDPF_OBFUSCATION
          i.key = idpf_key
        elsif i.algorithm == EncryptionHandler::ADOBE_OBFUSCATION
          i.key = adobe_key
        end
      end
      items.map { |i| [i.file_path, i] }.to_h
    end
  end
end
