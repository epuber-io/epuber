# encoding: utf-8

require_relative 'checker_transformer_base'


module Epuber
  class Transformer < CheckerTransformerBase
    require_relative 'transformer/text_transformer'

    def self.map_source_type__class
      {
        :result_text_xhtml_string => TextTransformer
      }.merge(super)
    end
  end
end
