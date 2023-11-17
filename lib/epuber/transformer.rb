# frozen_string_literal: true

require_relative 'checker_transformer_base'

module Epuber
  class Transformer < CheckerTransformerBase
    require_relative 'transformer/text_transformer'

    # @return [Hash<Symbol, Class>]
    #
    def self.map_source_type__class
      {
        result_text_xhtml_string: TextTransformer,
        source_text_file: TextTransformer,
      }.merge(super)
    end
  end
end
