# encoding: utf-8


module Epuber
  class Compiler
    module FileTypes
      require_relative 'abstract_file'

      class GeneratedFile < AbstractFile
        # @return [String | #to_s] files content
        #
        attr_accessor :content

        def process(opts = {})
          self.class.write_to_file(content.to_s, destination_path)
        end
      end
    end
  end
end
