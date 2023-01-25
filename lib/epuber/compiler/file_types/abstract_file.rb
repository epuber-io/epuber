# frozen_string_literal: true

module Epuber
  class Compiler
    module FileTypes
      class AbstractFile

        # @return [String] relative destination path
        #
        attr_accessor :destination_path

        # @return [Symbol] group of this file (:text, :image, :font, ...), see Epuber::Compiler::FileFinder::GROUP_EXTENSIONS
        #
        attr_accessor :group

        # @return [Set<Symbol>] list of properties
        #
        attr_accessor :properties

        # @return [Set<Symbol>] list of properties
        #
        def properties
          @properties ||= Set.new
        end


        # @return [String] final relative destination path from root of the package calculated by FileResolver
        #
        attr_accessor :pkg_destination_path

        # @return [String] final absolute destination path calculated by FileResolver
        #
        attr_accessor :final_destination_path

        # @return [Symbol] type of path, one of :spine, :manifest, :package
        #
        attr_accessor :path_type

        # @return [Epuber::Compiler::CompilationContext] non-nil value only during #process() method
        #
        attr_accessor :compilation_context

        def ==(other)
          self.class == other.class && final_destination_path == other.final_destination_path
        end


        ################################################################################################################

        # @param [String] source_path
        # @param [String] dest_path
        #
        # @return nil
        #
        def self.file_copy!(source_path, dest_path)
          FileUtils.mkdir_p(File.dirname(dest_path))

          FileUtils.cp(source_path, dest_path)
        end

        # @param [String | #to_s] content anything, that can be converted to string and should be written to file
        # @param [String] to_path  destination path
        #
        # @return nil
        #
        def self.write_to_file?(content, to_path)
          return true unless File.exist?(to_path)

          File.read(to_path) != content.to_s
        end

        # @param [String | #to_s] content anything, that can be converted to string and should be written to file
        # @param [String] to_path  destination path
        #
        # @return nil
        #
        def self.write_to_file(content, to_path)
          return unless write_to_file?(content, to_path)

          write_to_file!(content, to_path)
        end

        # @param [String | #to_s] content anything, that can be converted to string and should be written to file
        # @param [String] to_path  destination path
        #
        # @return nil
        #
        def self.write_to_file!(content, to_path)
          FileUtils.mkdir_p(File.dirname(to_path))

          File.open(to_path, 'w') do |file_handle|
            file_handle.write(content)
          end
        end
      end
    end
  end
end
