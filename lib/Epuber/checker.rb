# encoding: utf-8

require_relative 'checker_transformer_base'


module Epuber
  class Checker < CheckerTransformerBase
    require 'epuber/checker/text_checker'

    def self.map_source_type__class
      {
        :result_text_xhtml_string => TextChecker
      }.merge(super)
    end
  end
end
