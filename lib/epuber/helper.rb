# encoding: utf-8

module Epuber
  module Helper

    # @param [Book::TocItem] toc_item
    # @param [Compiler::FileResolver] file_resolver
    # @param [String] context_path
    #
    # @return [String]
    #
    def self.destination_path_for_toc_item(toc_item, file_resolver, context_path)
      file = file_resolver.file_from_request(toc_item.file_request)
      path = [file.final_destination_path, toc_item.file_fragment].compact.join('#')

      Pathname.new(path).relative_path_from(Pathname.new(context_path)).to_s
    end
  end
end
