# frozen_string_literal: true

require_relative 'checker_transformer_base'

module Epuber
  class Transformer < CheckerTransformerBase
    require_relative 'transformer/text_transformer'
    require_relative 'transformer/book_transformer'

    # @return [Hash<Symbol, Class>]
    #
    def self.map_source_type__class
      {
        result_text_xhtml_string: TextTransformer,
        source_text_file: TextTransformer,
        after_all_text_files: BookTransformer,
      }.merge(super)
    end
  end
end
