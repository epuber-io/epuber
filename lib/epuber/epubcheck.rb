# frozen_string_literal: true

require 'open3'

module Epuber
  class Epubcheck
    class << self
      # @param [String] path path to file
      #
      def check(path)
        res = system('epubcheck', path)

        UI.error!('Epubcheck failed') if res == false
      end
    end
  end
end
