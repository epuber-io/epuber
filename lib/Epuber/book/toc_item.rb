# encoding: utf-8

require_relative '../dsl/tree_object'
require_relative 'file'

module Epuber
  module Book
    class TocItem < DSL::TreeObject
      # @return [Epuber::Book::File]
      #
      attribute :file_obj,
                types: [Epuber::Book::File],
                auto_convert: { String => Epuber::Book::File },
                inherited: true

      # @return [String]
      #
      attribute :title

      # @return [Array<Symbol | Hash<Symbol, Object>>]
      #
      attribute :options,
                default_value: []



      # -------------- creating sub items -----------------

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
      # @param [String] file_path
      # @param [String] title
      #
      def file(file_path, title = nil, *opts)
        create_child_item do |item|
          unless file_path.nil?
            file_obj = Epuber::Book::File.new(file_path, group: :text)
            item.file_obj = file_obj
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

      # @param [String] title
      #
      def item(title, *opts)
        file(nil, title, *opts)
      end
    end
  end
end
