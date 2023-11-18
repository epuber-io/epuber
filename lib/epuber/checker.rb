# frozen_string_literal: true

require_relative 'checker_transformer_base'

module Epuber
  class Checker < CheckerTransformerBase
    require_relative 'checker/text_checker'
    require_relative 'checker/bookspec_checker'

    # @return [Hash<Symbol, Class>]
    #
    def self.map_source_type__class
      {
        result_text_xhtml_string: TextChecker,
        source_text_file: TextChecker,
        bookspec: BookspecChecker,
      }.merge(super)
    end

    def warning(messsage, location: nil)
      UI.warning(messsage, location: location)
    end

    def error(messsage, location: nil)
      if Config.instance.release_build
        UI.error!(messsage, location: location)
      else
        UI.error(messsage, location: location)
      end
    end
  end
end
