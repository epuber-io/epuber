# frozen_string_literal: true

module Epuber
  class Compiler
    module FileTypes
      require_relative 'generated_file'

      class MimeTypeFile < GeneratedFile
        def initialize
          super

          self.path_type        = :package
          self.destination_path = 'mimetype'
          self.content          = 'application/epub+zip'
        end
      end
    end
  end
end
