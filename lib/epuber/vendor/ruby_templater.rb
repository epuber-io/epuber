# frozen_string_literal: true

require_relative 'hash_binding'

module Epuber
  class RubyTemplater
    # @return [String]
    #
    attr_accessor :source_text

    # @return [String]
    #
    attr_accessor :file_path

    # @return [Hash]
    #
    attr_accessor :locals

    # @param source [String]
    #
    # @return [self]
    #
    def self.from_source(source, file_path = nil)
      inst = new
      inst.source_text = source
      inst.file_path = file_path
      inst
    end

    # @param file [String, File]
    #
    # @return [self]
    #
    def self.from_file(file)
      file_obj = if file.is_a?(String)
                   File.new(file, 'r')
                 else
                   file
                 end

      from_source(file_obj.read, file_obj.path)
    end


    # ----------------------------------------------------------------------------- #
    # DSL methods


    # @param locals [Hash]
    #
    # @return [self]
    #
    def with_locals(locals = {})
      self.locals = locals
      self
    end

    # @return [String]
    #
    def render
      hash_binding = HashBinding.new(locals)
      eval_string = %(%(#{source_text}))
      eval(eval_string, hash_binding.get_binding) # rubocop:disable Security/Eval
    end
  end
end
