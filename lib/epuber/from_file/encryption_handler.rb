# frozen_string_literal: true

require 'nokogiri'
require 'uuidtools'
require 'digest'

module Epuber
  module EncryptionHandler
    class EncryptionItem
      # @return [String]
      #
      attr_accessor :algorithm

      # @return [String]
      #
      attr_accessor :file_path

      # @return [String, nil]
      #
      attr_accessor :key

      def initialize(algorithm, file_path)
        @algorithm = algorithm
        @file_path = file_path
      end
    end

    ADOBE_OBFUSCATION = 'http://ns.adobe.com/pdf/enc#RC'
    IDPF_OBFUSCATION = 'http://www.idpf.org/2008/embedding'

    # @param [String] key
    # @param [String] data
    # @param [String] algorithm
    #
    def self.decrypt_font_data(key, data, algorithm)
      is_adobe = algorithm == ADOBE_OBFUSCATION
      crypt_len = is_adobe ? 1024 : 1040
      crypt = data.byteslice(0, crypt_len).bytes
      key_cycle = key.bytes.cycle
      decrypt = crypt.each_with_object([]) { |x, acc| acc << (x ^ key_cycle.next) }.pack('C*')
      decrypt + data.byteslice(crypt_len..-1)
    end

    # @param [String] raw_unique_identifier
    #
    # @return [String, nil]
    #
    def self.parse_idpf_key(raw_unique_identifier)
      Digest::SHA1.digest(raw_unique_identifier.strip.gsub(/[\u0020\u0009\u000d\u000a]/, ''))
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
  end
end
