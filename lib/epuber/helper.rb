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
      file = file_resolver.file_from_request(toc_item.full_file_request)
      path = file.final_destination_path

      pattern        = toc_item.file_request.source_pattern
      fragment_index = pattern.index('#')
      path           += pattern[fragment_index..-1] unless fragment_index.nil?

      Pathname.new(path).relative_path_from(Pathname.new(context_path)).to_s
    end
  end
end
