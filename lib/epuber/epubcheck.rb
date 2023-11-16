# frozen_string_literal: true

module Epuber
  class Epubcheck
    class << self
      # @param [String] path path to file
      #
      def check(path)
        res = system('epubcheck', path)

        UI.error!('Epubcheck failed') unless res
      end
    end
  end
end
