# encoding: utf-8

require 'nokogiri'


module Epuber
  class Compiler
    module FileTypes
      require_relative 'source_file'

      class BadeFile < SourceFile
        def process(opts = {})
          raise 'To Implement'
        end
      end
    end
  end
end
