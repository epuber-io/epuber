require_relative '../dsl/tree_object'

module Epuber
  module Book
    class TocItem < DSL::TreeObject

      # @return [String]
      #
      attribute :file_path,
                inherited: true

      # @return [String]
      #
      attribute :title

      # @return [Array<Symbol | Hash<Symbol, Object>>]
      #
      attribute :options,
                default_value: []


      # -------------- creating sub items -----------------

      # Creating sub item from file
      #
      # @example
      #      toc.file 'ch01', 'Chapter 1', :landmark_start_page
      #      toc.file 'ch02', :landmark_copyright
      #      toc.file 'ch03', :linear => false
      #      toc.file 'ch04', linear: false
      #
      # @param [String] file_path
      # @param [String] title
      #
      # TODO title is optional
      # TODO check opts for :landmark_*, linear: true
      #
      def file(file_path, title = nil, *opts)
        create_child_item do |item|
          item.file_path = file_path

          if title.is_a?(String)
            item.title = title
          else
            opts.unshift(title)
          end

          item.options = opts.map do |i|
            if i.kind_of? Hash
              i.map do |j_key, j_value|
                { j_key => j_value }
              end
            else
              i
            end
          end.flatten

          yield item if block_given?
        end
      end

      # @param [String] title
      #
      def item(title, *opts)
        file(nil, title, *opts)
      end


      # TODO glob
      # TODO files
    end
  end
end
