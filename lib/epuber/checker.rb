# frozen_string_literal: true

require_relative 'checker_transformer_base'

module Epuber
  class Checker < CheckerTransformerBase
    require_relative 'checker/text_checker'

    # @return [Hash<Symbol, Class>]
    #
    def self.map_source_type__class
      {
        :result_text_xhtml_string => TextChecker,
        :source_text_file         => TextChecker,
      }.merge(super)
    end
  end
end
