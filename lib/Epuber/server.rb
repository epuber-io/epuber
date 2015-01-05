# encoding: utf-8

require 'pathname'

require 'sinatra/base'
require 'sinatra-websocket'

require 'nokogiri'
require 'listen'

require_relative 'book'
require_relative 'config'


module Epuber

  # API:
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
    end

    # @return [Epuber::Book::Book]
    #
    def book
      self.class.book
    end

    # @return [Epuber::Book::Target]
    #
    def target
      @target ||= self.class.target
    end

    attr_writer :target


    # @return [String] base path
    #
    def build_path
      Config.instance.build_path(target)
    end

    # @return [Array<SinatraWebsocket::Connection>]
    #
    attr_reader :sockets



    # -------------------------------------------------- #

    # @!group Helpers

    # @param pattern [String]
    #
    # @return [String] path to file
    #
    def find_file(pattern = params[:splat].first)
      paths = nil

      Dir.chdir(build_path) do
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
        abs_path      = File.expand_path(node[attribute_name], File.join(build_path, File.dirname(context_path)))
        relative_path = abs_path.sub(File.expand_path(build_path), '')

        node[attribute_name] = File.join('', 'raw', relative_path.to_s)
      end
    end

    # @param html_doc [Nokogiri::HTML::Document]
    #
    def add_auto_refresh_script(html_doc)
      head = html_doc.css('head').first
      head << File.read(File.expand_path(File.join('server', 'auto_refresh.html'), File.dirname(__FILE__)))
    end

    def compile
      require_relative 'compiler'
      Epuber::Compiler.new(book, target).compile(Epuber::Config.instance.build_path(target))
    end

    def notify_clients
      puts "sockets.count = #{sockets.count}"
      sockets.each do |ws|
        ws.send('ia')
      end
    end

    def changes_detected(_modified, _added, _removed)
      puts 'Compiling'.yellow
      compile

      puts 'Notifying clients'.yellow
      notify_clients
    end


    # -------------------------------------------------- #

    def initialize
      super
      @sockets = []

      @listener = Listen.to(Config.instance.project_path, debug: true) do |modified, added, removed|
        changes_detected(modified, added, removed)
      end

      @listener.start

      @listener.ignore(%r{#{Config.instance.working_path}})
      @listener.ignore(%r{#{Config::WORKING_PATH}/})
    end


    # -------------------------------------------------- #

    # @!group Sinatra things

    enable :sessions

    # Book page
    #
    get '/' do
      if !request.websocket?
        puts 'normal / request'.green

        nokogiri do |xml|
          xml.pre book.inspect
        end
      else

          puts 'websocket / request'.green
          request.websocket do |ws|

            thread = nil

            ws.onopen do
              sockets << ws

              thread = Thread.new do
                loop do
                  sleep(10)
                  ws.send('heartbeat')
                end
              end
            end

            ws.onmessage do |msg|
              puts "WS: Received message: #{msg}".green
            end

            ws.onclose do
              puts 'websocket closed'.red
              sockets.delete(ws)
              thread.kill
            end
          end


      end
    end

    # TOC page
    #
    get '/toc' do
      nokogiri do |xml|
        xml.pre book.root_toc.inspect
      end
    end

    get '/toc/*' do
      path = find_file
      next [404] if path.nil?

      puts "/toc/*: founded file #{path}".green
      html_doc = Nokogiri::HTML(File.open(File.join(build_path, path)))

      fix_links(html_doc, path, 'img', 'src') # images
      fix_links(html_doc, path, 'script', 'src') # javascript
      fix_links(html_doc, path, 'link', 'href') # css styles
      add_auto_refresh_script(html_doc)

      html_doc.to_html
    end

    # Returns file with path or pattern, base_path is epub root
    #
    get '/raw/*' do
      path = find_file
      next [404] if path.nil?

      puts "/raw/*: founded file #{path}".green
      send_file(File.expand_path(path, build_path))
    end


    def watch_connections
      @watch_connections ||= []
    end

    get '/ajax/watch_changes' do
      stream(:keep_open) do |out|
        watch_connections << out
      end
    end
  end
end
