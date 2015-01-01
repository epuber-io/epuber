# encoding: utf-8

require 'sinatra/base'

require 'nokogiri'
require 'pathname'

require_relative 'book'


module Epuber

  # API:
  #    /  -- starting point / landing page / dashboard (landibook cover, book version, ...)
  #    /toc   -- only toc
  #    /toc/:file_pattern -- text file matching pattern (for example: /toc/s01)
  # [LATER]   /file/<path-or-pattern> -- displays pretty file (image, text file) (for example: /file/text/s01.xhtml or /file/text/s01.bade)
  #
  class Server < Sinatra::Base
    class << self
      # @return [Epuber::Book::Book]
      #
      attr_accessor :book

      # @return [Epuber::Book::Target]
      #
      attr_accessor :target

      # @return [String]
      #
      attr_accessor :base_path
    end

    def method_missing(name, *args)
      return self.class.send(name) if self.class.respond_to?(name)
      super
    end


    # -------------------------------------------------- #

    # @!group Helpers

    # @param pattern [String]
    #
    # @return [String] path to file
    #
    def find_file(pattern = params[:splat].first)
      paths = nil

      Dir.chdir(base_path) do
        paths = Dir.glob(pattern)
        paths = Dir.glob("**/#{pattern}") if paths.empty?

        paths = Dir.glob("**/#{pattern}*") if paths.empty?
        paths = Dir.glob("**/#{pattern}.*") if paths.empty?
      end

      paths.first
    end

    # @param html_doc [Nokogiri::HTML::Document]
    # @param context_path [String]
    # @param css_selector [String]
    # @param attribute_name [String]
    #
    def fix_links(html_doc, context_path, css_selector, attribute_name)
      img_nodes = html_doc.css(css_selector)
      img_nodes.each do |node|
        img_path = Pathname(node[attribute_name])

        abs_path = img_path.expand_path(File.join(base_path, File.dirname(context_path)))
        relative_path = abs_path.relative_path_from(Pathname(File.expand_path(base_path)))

        node[attribute_name] = File.join('', 'raw', relative_path.to_s)
      end
    end


    # -------------------------------------------------- #

    # @!group Sinatra things

    enable :sessions

    connections = []

    get '/' do
      nokogiri do |xml|
        xml.pre book.inspect
      end
    end


    get '/toc' do
      nokogiri do |xml|
        xml.pre book.root_toc.inspect
      end
    end

    get '/toc/*' do
      path = find_file
      next [404] if path.nil?

      puts "/toc/*: founded file #{path}"
      html_doc = Nokogiri::HTML(File.open(File.join(base_path, path)))

      fix_links(html_doc, path, 'img', 'src') # images
      fix_links(html_doc, path, 'script', 'src') # javascript
      fix_links(html_doc, path, 'link', 'href') # css styles

      html_doc.to_html
    end


    # Returns file with path or pattern, base_path is epub root
    #
    get '/raw/*' do
      path = find_file

      next [404] if path.nil?
      puts "/raw/*: founded file #{path}"
      send_file(File.expand_path(path, base_path))
    end



    get '/time' do
      File.read('../json_ajax_experiment.html')
    end

    get '/time_ajax' do
      stream(:keep_open) do |out|
        connections << out
      end
    end

    Thread.new {
      loop do
        sleep(100)

        puts "Checking, connections count = #{connections.count}"

        connections.each { |out|
          time = Time.now.to_s
          out << time
          out.close
          puts "Just sent #{time}"
        }

        connections.reject!(&:closed?)
      end
    }
  end
end


