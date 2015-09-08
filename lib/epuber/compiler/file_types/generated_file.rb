# encoding: utf-8


module Epuber
  class Compiler
    module FileTypes
      require_relative 'abstract_file'

      class GeneratedFile < AbstractFile

        # @return [String] relative source path
        #
        attr_accessor :content

        # @param [String] destination_path relative path from project root to result file
        # @param [Symbol] group  group of file, see Epuber::Compiler::FileFinder::GROUP_EXTENSIONS
        # @param [Array<Symbol>, Set<Symbol>] properties  list of properties
        #
        def initialize(destination_path, group: nil, properties: [])
          @destination_path = destination_path
          @properties = properties.to_set
          @group      = group
        end

        def process
          self.class.write_to_file(content, destination_path)
        end
      end
    end
  end
end
