
require_relative '../dsl/tree_object'


module Epuber

	class TocItem < DSLTreeObject

		# @return [String]
		#
		attribute :file_path,
				  :inherited => true

		# @return [String]
		#
		attribute :title

		# @return [Array<Symbol | Hash<Symbol, Object>>]
		#
		attribute :options,
				  :default_value => []


		# -------------- creating sub items -----------------

		# @param [String] file_path
		# @param [String] title
		#
		# TODO title is optional
		# TODO check opts for :landmark_*, :linear =>
		#
		def file(file_path, title, *opts)
			create_child_item do |item|
				item.file_path = file_path
				item.title = title
				item.options = opts.map do |i|
					if i.kind_of? Hash
						i.map do |j_key, j_value|
							{ j_key => j_value }
						end
					else
						i
					end
				end.flatten
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
