# encoding: utf-8

require 'pathname'

require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra-websocket'

require 'nokogiri'
require 'listen'

require 'active_support/core_ext/object/try'

require_relative 'book'
require_relative 'config'
require_relative 'compiler'
require_relative 'vendor/hash_binding'

require 'bade/runtime/block'


def block(*args, &block)
  Bade::Runtime::Block.new(*args, &block)
end


class Proc
  def call_with_vars(vars, *args)
    Struct.new(*vars.keys).new(*vars.values).instance_exec(*args, &self)
  end
end


module Epuber

  # API:
  # [LATER]   /file/<path-or-pattern> -- displays pretty file (image, text file) (for example: /file/text/s01.xhtml or /file/text/s01.bade)
  #
  class Server < Sinatra::Base
    class ShowExceptions < Sinatra::ShowExceptions
      def call(env)
        e = env['sinatra.error']

        if prefers_plain_text?(env)
          content_type = 'text/plain'
          body = [dump_exception(e)]
        else
          content_type = 'text/html'
          body = pretty(env, e)
        end

        unless body.is_a?(Array)
          body = [body]
        end

        [500, { 'Content-Type'   => content_type,
                'Content-Length' => Rack::Utils.bytesize(body.join).to_s },
         body]
      end
    end

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
      self.class.target
    end

    # @return [Array<Epuber::Book::File>]
    #
    attr_accessor :spine


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
      when :get
        puts " GET: #{message}"
      when :ws
        puts "  WS: #{message}"
      else
        raise "Unknown log level #{level}"
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

    # @param index [Fixnum]
    # @return [Epuber::Book::File, nil]
    #
    def spine_file_at(index)
      if index >= 0 && index < spine.count
        spine[index]
      end
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

    def add_script_file_to_head(html_doc, file_name, *args)
      source = File.read(File.expand_path("server/#{file_name}", File.dirname(__FILE__)))

      args.each do |hash|
        hash.each do |key, value|
          opt_value = if value
                        "'#{value}'"
                      else
                        'null'
                      end
          source.gsub!(key, opt_value)
        end
      end

      script_node = html_doc.create_element('script', source, type: 'text/javascript')

      head = html_doc.css('head').first

      if head.nil?
        head = html_doc.create_element('head')
        html_doc.css('html').first.add_child(head)
      end
      head.add_child(script_node)
    end

    # @param html_doc [Nokogiri::HTML::Document]
    #
    def add_auto_refresh_script(html_doc)
      add_script_file_to_head(html_doc, 'auto_refresh.js')
    end

    # @param html_doc [Nokogiri::HTML::Document]
    #
    def add_keyboard_control_script(html_doc, previous_path, next_path)
      add_script_file_to_head(html_doc, 'keyboard_control.js',
                              '$previous_path' => previous_path,
                              '$next_path' => next_path)
    end

    def compile
      compiler = Epuber::Compiler.new(book, target)
      compiler.compile(build_path)
      self.spine = compiler.spine
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

    def render_bade(name, *args)
      common_path = File.expand_path('server/common.bade', File.dirname(__FILE__))
      source_path = File.expand_path("server/#{name}", File.dirname(__FILE__))
      source      = ::File.read(common_path) + "\n" + ::File.read(source_path)

      parsed      = Bade::Parser.new(file: source_path).parse(source)
      lam         = Bade::RubyGenerator.node_to_lambda(parsed, new_line: '\n', indent: '  ')
      #_log :get, "#{name} lambda = #{Bade::RubyGenerator.node_to_lambda_string(parsed, new_line: '', indent: '')}"
      result      = lam.call_with_vars(*args, book: book, target: target)
      [200, result]
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

    def handle_websocket(path)
      _log :ws, "#{path}: start"
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
          _log :ws, "#{path}: received message: #{msg.inspect}"
        end

        ws.onclose do
          _log :ws, "#{path}: socket closed"
          sockets.delete(ws)
          thread.kill
        end
      end
    end

    # -------------------------------------------------- #

    # @!group Sinatra things

    register Sinatra::Namespace

    enable :logging
    enable :sessions
    disable :show_exceptions
    disable :dump_errors
    disable :raise_errors

    error do
      ShowExceptions.new(self).call(env)
    end


    # Book page
    #
    get '/' do
      _log :get, '/'
      render_bade('book.bade')
    end



    # ------------------------------------------
    # @group TOC

    # TOC page
    #
    namespace '/toc' do
      get '/?' do
        render_bade('toc.bade')
      end

      get '/*' do
        next handle_websocket("/toc/#{params[:splat].first}") if request.websocket?

        path = find_file
        next not_found if path.nil?

        _log :get, "/toc/#{params[:splat].first}: founded file #{path}"
        html_doc = Nokogiri::HTML(File.open(File.join(build_path, path)))

        fix_links(html_doc, path, 'img', 'src') # images
        fix_links(html_doc, path, 'script', 'src') # javascript
        fix_links(html_doc, path, 'link', 'href') # css styles
        add_auto_refresh_script(html_doc)

        current_index = spine.index { |file| path.end_with?(file.destination_path.to_s) }
        previous_path = spine_file_at(current_index - 1).try(:destination_path).try(:to_s)
        next_path     = spine_file_at(current_index + 1).try(:destination_path).try(:to_s)
        add_keyboard_control_script(html_doc, previous_path, next_path)

        session[:current_page] = path

        html_doc.to_html
      end
    end

    # ----------------------------------
    # @group Raw files

    # Returns file with path or pattern, base_path is epub root
    #
    get '/raw/*' do
      path = find_file
      next [404] if path.nil?

      _log :get, "/raw/#{params[:splat].first}: founded file #{path}"
      send_file(File.expand_path(path, build_path))
    end


    namespace '/server' do
      get '/raw/*' do
        file_path = File.expand_path("server/#{params[:splat].first}", File.dirname(__FILE__))
        _log :get, "/server/raw/#{params[:splat].first} -> #{file_path}"

        next not_found unless File.exists?(file_path)

        last_modified(File.mtime(file_path))

        case File.extname(file_path)
        when '.styl'
          require 'stylus'
          body(Stylus.compile(::File.new(file_path)))
        else
          send_file(file_path)
        end
      end
    end
  end
end
