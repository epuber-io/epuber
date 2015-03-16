# encoding: utf-8

module Epuber
  class Transformer < CheckerTransformerBase
    require 'epuber/transformer/text_transformer'

    def self.map_source_type__class
      {
        :result_text_xhtml_string => TextTransformer
      }.merge(super)
    end
  end
end
