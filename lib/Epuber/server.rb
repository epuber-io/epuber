# encoding: utf-8

require 'pathname'

require 'sinatra/base'
require 'sinatra-websocket'

require 'nokogiri'
require 'listen'

require 'deep_clone'

require_relative 'book'
require_relative 'config'
require_relative 'compiler'


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
      Epuber::Config.instance.build_path(target)
    end

    # @return [Array<SinatraWebsocket::Connection>]
    #
    attr_reader :sockets


    # @param level [Symbol]
    # @param message [String]
    #
    # @return nil
    #
    def _log(level, message)
      case level
      when :ui
        puts message
      when :info
        puts "INFO: #{message}"
      else
        raise "Unknown level #{level}"
      end
    end

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
      Epuber::Compiler.new(DeepClone.clone(book), DeepClone.clone(target)).compile(build_path)
    end

    # @param message [String]
    #
    def send_to_clients(message)
      _log :info, "sending message to clients #{message.inspect}"

      sockets.each do |ws|
        ws.send(message)
      end
    end

    # @param type [Symbol]
    def notify_clients(type)
      _log :info, "Notifying clients with type #{type.inspect}"
      case type
      when :styles
        send_to_clients('ia')
      when :reload
        send_to_clients('r')
      else
        raise 'Not known type'
      end
    end

    # @param _modified [Array<String>]
    # @param _added [Array<String>]
    # @param _removed [Array<String>]
    #
    def changes_detected(_modified, _added, _removed)
      _log :ui, 'Compiling'
      compile

      _log :ui, 'Notifying clients'
      if _modified.all? { |file| file.end_with?(*Epuber::Compiler::GROUP_EXTENSIONS[:style]) }
        notify_clients(:styles)
      else
        notify_clients(:reload)
      end
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

      _log :ui, 'Init compile'
      compile
    end


    # -------------------------------------------------- #

    # @!group Sinatra things

    enable :sessions

    # Book page
    #
    get '/' do
      if !request.websocket?
        _log :info, '/ -- normal request'

        nokogiri do |xml|
          xml.pre book.inspect
        end
      else
        _log :info, '/ -- websocket request'
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
            _log :info, "WS: Received message: #{msg}"
          end

          ws.onclose do
            _log :info, 'websocket closed'
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

      _log :info, "/toc/#{params[:splat].first}: founded file #{path}"
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

      _log :info, "/raw/#{params[:splat].first}: founded file #{path}"
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
