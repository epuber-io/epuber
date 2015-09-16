# encoding: utf-8

require_relative '../dsl/tree_object'


module Epuber
  class Book
    require_relative 'file_request'

    class TocItem < DSL::TreeObject
      # @return [Epuber::Book::FileRequest]
      #
      attribute :file_request,
                types:        [FileRequest],
                auto_convert: { String => FileRequest },
                inherited:    true

      # @return [String]
      #
      attribute :title

      # @return [Array<Symbol | Hash<Symbol, Object>>]
      #
      attribute :options,
                default_value: []



      # --------------

      # @return [Array<Symbol>]
      #
      def landmarks
        options.select do |item|
          item.is_a?(Symbol) && item.to_s.start_with?('landmark')
        end
      end

      # @return [Bool]
      #
      def linear?
        first = options.select do |item|
          item.is_a?(Hash) && (item.include?(:linear) || item.include?('linear'))
        end.first

        if first.nil?
          true
        else
          first.values.first
        end
      end


      # -------------- creating sub items -----------------

      # Creating sub item from file
      #
      # @example
      #      toc.file 'ch01', 'Chapter 1', :landmark_start_page
      #      toc.file 'ch02', :landmark_copyright
      #      toc.file 'ch03', :linear => false
      #      toc.file 'ch04', linear: false
      #
      # @param [String] file_path pattern describing path to file
      # @param [String] title title of this item
      #
      def file(file_path, title = nil, *opts)
        create_child_item do |item|
          unless file_path.nil?
            file_obj = FileRequest.new(file_path, group: :text)
            item.file_request = file_obj
          end

          if title.is_a?(String)
            item.title = title
          else
            opts.unshift(title)
          end

          item.options = opts.map do |i|
            if i.is_a?(Hash)
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

      # Creating sub item without reference to file
      #
      # @param [String] title
      #
      def item(title, *opts)
        file(nil, title, *opts)
      end
    end
  end
end
