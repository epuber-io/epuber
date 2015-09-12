# encoding: utf-8

require 'nokogiri'


module Epuber
  class Compiler
    module FileTypes
      require_relative 'source_file'

      class XHTMLFile < SourceFile
        def process(opts = {})
          raise 'To implement'
        end
      end
    end
  end
end
