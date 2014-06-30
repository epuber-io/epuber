module Epuber

	class Contributor

		# File-as of contributor used in .opf file
		# @return [String] pretty name
		#
		attr_accessor :file_as

		# Pretty name of contributor used in .opf file and copyright page
		# @return [String] pretty name
		#
		attr_accessor :pretty_name

		# Role of contributor
		# @return [String] role
		#
		attr_accessor :role


		# @param [String] pretty_name pretty name of contributor
		# @param [String] file_as file as of contributor
		#
		def initialize(pretty_name, file_as, role)
			@file_as     = file_as
			@pretty_name = pretty_name
			@role        = role
		end


		def self.create(obj, role)
			if obj.is_a? Hash and obj.has_key?(:first_name)
				return NormalContributor.new(obj[:first_name], obj[:last_name], role)
			end
		end
	end


	class NormalContributor < Contributor

		# @return [String] first name of contributor
		attr_accessor :first_name

		# @return [String] lase name of contributor
		attr_accessor :last_name


		# @param [String] first_name first name of contributor
		# @param [String] last_name last name of contributor
		#
		def initialize(first_name, last_name, role)
			super(nil, nil, role)

			@first_name = first_name
			@last_name  = last_name
		end


		# ---- Overriden Getters -----
		def pretty_name
			"#{@first_name} #{@last_name}"
		end

		def file_as
			"#{@last_name.upcase}, #{@first_name}"
		end

		# ------ Overriden Setters ------
		def pretty_name=
			raise(Exception, 'Cannot write pretty_name property on NormalContributor')
		end

		def file_as=
			raise(Exception, 'Cannot write file_as property on NormalContributor')
		end
	end
end
