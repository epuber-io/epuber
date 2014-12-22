
require 'pathname'
require 'fileutils'

require_relative 'main_controller/opf'

require_relative 'book'


module Epuber
  class MainController
    include OPF

    BASE_PATH = '.epuber'

    # @param targets [Array<String>] targets names
    #
    def compile_targets(targets = nil)

      # TODO: DEBUG, remove next line
      FileUtils.rmtree(BASE_PATH)


      bookspecs = Pathname.glob(Pathname.pwd + '*.bookspec')

      raise 'Not found .bookspec file' if bookspecs.count.zero?

      bookspecs.each do |bookspec_file_pathname|
        # @type book [Book::Book]
        # @type bookspec_file_pathname [Pathname]

        @book = Book::Book.from_file(bookspec_file_pathname.to_s)
        @book.validate

        puts "loaded book `#{@book.title}`"

        # when the list of targets is nil use them all
        targets ||= @book.targets.map { |target| target.name }

        targets.each do |target_name|
          process_target_named(target_name)
        end
      end
    end


    private

    # @param target_name [String]
    #
    def process_target_named(target_name)
      @target = target_named(target_name)

      dir_name = File.join(BASE_PATH, 'build', target_name.to_s)
      FileUtils.mkdir_p(dir_name)

      @output_dir = File.absolute_path(dir_name, Dir.pwd)

      puts "  handling target `#{@target.name}` in build dir `#{@output_dir}`"

      process_other_files
      process_toc_item(@book.root_toc)
      generate_opf(@book, @target)

      # TODO: create other files (.opf, .ncx, ...)

      # TODO: pack to epub files

    end

    def process_other_files
      @target.files.each { |file|
        process_file(file)
      }
    end

    # @param toc_item [Epuber::Book::TocItem]
    #
    def process_toc_item(toc_item)
      unless toc_item.file_path.nil?
        puts "    processing toc item #{toc_item.file_path}"

        process_file(toc_item.file_path) unless toc_item.file_path.nil?

      end

      toc_item.child_items.each { |child|
        process_toc_item(child)
      }
    end

    # @param file [String, Epuber::Book::File]
    #
    def process_file(file)
      file_pathname = find_file(file)

      case file_pathname.extname
      when '.xhtml', '.css'
        copy_file_to_destination(file_pathname.to_s)
      end
    end

    # @param file_or_pattern [String, Epuber::Book::File]
    # @return [Pathname]
    #
    def find_file(file_or_pattern)
      pattern = if file_or_pattern.is_a?(Epuber::Book::File)
                  file_or_pattern.source_path
                else
                  file_or_pattern
                end

      # @type file_path_names [Array<Pathname>]
      file_path_names = Pathname.glob("**/#{pattern}*")

      file_path_names.select! { |file_pathname|
        !file_pathname.to_s.include?(BASE_PATH)
      }

      raise "not found file matching pattern `#{pattern}`" if file_path_names.empty?
      raise 'found too many files' if file_path_names.count >= 2

      file_path_names.first
    end

    # @param from_path [String]
    #
    def copy_file_to_destination(from_path)
      dest_path = File.join(@output_dir, 'OEBPS', from_path.to_s)
      FileUtils.mkdir_p(Pathname.new(dest_path).dirname)
      FileUtils.cp(from_path.to_s, dest_path)
      # puts "copied file from #{from_path} to path #{Pathname.new(dest_path).relative_path_from(Pathname.new(Dir.pwd))}"
    end

    # @param target_name [String]
    #
    # @return [Epuber::Book::Target]
    #
    def target_named(target_name)
      target = @book.targets.find { |target|
        target.name == target_name
      }

      raise "Not found target with name #{target_name}" if target.nil?
      target
    end
  end
end
