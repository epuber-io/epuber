# encoding: utf-8


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

        # @return [Set<String>] list of properties
        #
        attr_accessor :properties


        # @param [String] source_path
        # @param [String] dest_path
        #
        # @return nil
        #
        def self.file_copy(source_path, dest_path)
          return if FileUtils.uptodate?(dest_path, [source_path])
          return if ::File.exists?(dest_path) && FileUtils.compare_file(dest_path, source_path)

          file_copy!(source_path, dest_path)
        end

        # @param [String] source_path
        # @param [String] dest_path
        #
        # @return nil
        #
        def self.file_copy!(source_path, dest_path)
          FileUtils.cp(source_path, dest_path)
        end

        # @param [String | #to_s] content anything, that can be converted to string and should be written to file
        # @param [String] to_path  destination path
        #
        # @return nil
        #
        def self.write_to_file(content, to_path)
          original_content = if ::File.exists?(to_path)
                               ::File.read(to_path)
                             end

          should_write = if original_content.nil?
                           true
                         elsif content.is_a?(String)
                           original_content != content
                         else
                           original_content != content.to_s
                         end

          return unless should_write

          write_to_file!(content, to_path)
        end

        # @param [String | #to_s] content anything, that can be converted to string and should be written to file
        # @param [String] to_path  destination path
        #
        # @return nil
        #
        def self.write_to_file!(content, to_path)
          ::File.open(to_path, 'w') do |file_handle|
            file_handle.write(content)
          end
        end
      end
    end
  end
end
