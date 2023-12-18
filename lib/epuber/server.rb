# frozen_string_literal: true

require 'stringio'

require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra-websocket'

require 'nokogiri'
require 'listen'

require 'active_support'

require_relative 'compiler'
require_relative 'vendor/hash_binding'
require_relative 'helper'

require 'bade'
require 'epuber-stylus'
require 'coffee-script'

require_relative 'third_party/bower'


module Epuber
  # API:
  # [LATER]   /file/<path-or-pattern> -- displays pretty file (image, text file) (for example: /file/text/s01.xhtml or
  #                                      /file/text/s01.bade)
  #
  class Server < Sinatra::Base
    require_relative 'server/handlers'

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

        body = [body] unless body.is_a?(Array)

        [500, { 'Content-Type' => content_type,
                'Content-Length' => Rack::Utils.bytesize(body.join).to_s },
         body]
      end
    end

    def self.instance_class_accessor(name)
      instance_name = "@#{name}"

      define_singleton_method(name) do
        instance_variable_get(instance_name)
      end
      define_singleton_method("#{name}=") do |new_value|
        instance_variable_set(instance_name, new_value)
      end

      define_method(name) do
        self.class.send(name)
      end
      define_method("#{name}=") do |new_value|
        self.class.send("#{name}=", new_value)
      end
    end

    # @return [Epuber::Book::Book]
    #
    instance_class_accessor :book

    # @return [Epuber::Book::Target]
    #
    instance_class_accessor :target

    # @return [FalseClass, TrueClass]
    #
    instance_class_accessor :verbose

    # @return [Epuber::Compiler::FileResolver]
    #
    instance_class_accessor :file_resolver

    # @return [Array<Epuber::Compiler::File>]
    #
    instance_class_accessor :spine

    # @return [Array<SinatraWebsocket::Connection>]
    #
    instance_class_accessor :sockets

    def self.sockets
      @sockets ||= []
    end

    # @return [Listener]
    #
    instance_class_accessor :listener

    # @return nil
    #
    def self.run!(book, target, verbose: false)
      Encoding.default_internal = Encoding::UTF_8 if Encoding.default_internal.nil?

      self.book = book
      self.target = target
      self.verbose = verbose

      start_listening_if_needed

      old_stderr = $stderr
      $stderr = StringIO.new unless verbose

      super() do |server|
        $stderr = old_stderr
        UI.puts "Started development server on #{server.host}:#{server.port}"

        host = if server.host == '0.0.0.0'
                 'localhost'
               else
                 server.host
               end

        yield URI("http://#{host}:#{server.port}") if block_given?
      end
    end

    def self.verbose=(verbose)
      @verbose = verbose
      @default_thin_logger ||= Thin::Logging.logger

      if verbose
        Thin::Logging.logger = @default_thin_logger
      else
        Thin::Logging.logger = Logger.new(nil)
        Thin::Logging.logger.level = :fatal
      end

      set :logging, verbose
    end

    def initialize
      super
      _log :ui, 'Init compile'

      self.class.compile_book
    end

    def self.start_listening_if_needed
      return unless listener.nil?

      self.listener = Listen.to(Config.instance.project_path, debug: true) do |modified, added, removed|
        changes_detected(modified, added, removed)
      rescue StandardError => e
        # print error, do not send error further, listener will die otherwise
        warn e
        warn e.backtrace
      end

      listener.ignore(/\.idea/)
      listener.ignore(/#{Config.instance.working_path}/)
      listener.ignore(%r{#{Config::WORKING_PATH}/})

      listener.start
    end

    # @return [String] base path
    #
    def self.build_path
      Epuber::Config.instance.build_path(target)
    end

    # @return [String] base path
    #
    def build_path
      self.class.build_path
    end

    # @param [Symbol] level
    # @param [String] message
    #
    # @return nil
    #
    def self._log(level, message)
      case level
      when :ui
        UI.puts message
      when :info
        UI.puts "INFO: #{message}" if verbose
      when :get
        UI.puts " GET: #{message}" if verbose
      when :ws
        UI.puts "  WS: #{message}" if verbose
      else
        raise "Unknown log level #{level}"
      end
    end

    def _log(level, message)
      self.class._log(level, message)
    end


    # -------------------------------------------------- #

    # @!group Helpers

    # @param [String] pattern
    #
    # @return [String] path to file
    #
    def find_file(pattern = params[:splat].first, source_path: build_path)
      finder = Compiler::FileFinders::Normal.new(source_path)
      finder.find_files(pattern).first
    end

    # @param [Fixnum] index
    # @return [Epuber::Book::File, nil]
    #
    def spine_file_at(index)
      return unless !file_resolver.nil? && index >= 0 && index < file_resolver.spine_files.count

      file_resolver.spine_files[index]
    end

    # @param [String] path
    #
    # @return [String]
    #
    def self.relative_path_to_book_file(path)
      file = file_resolver.file_with_source_path(path)
      return if file.nil?

      file.pkg_destination_path
    end

    def add_script_file_to_head(html_doc, file_name, *args)
      source = File.read(File.expand_path("server/#{file_name}", File.dirname(__FILE__)))

      source = CoffeeScript.compile(source) if File.extname(file_name) == '.coffee'

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

      source = yield source if block_given?
      add_script_to_head(html_doc, source)
    end

    # @param [Nokogiri::HTML::Document] html_doc
    # @param [String] script_text
    #
    def add_script_to_head(html_doc, script_text)
      script_node = html_doc.create_element('script', script_text, type: 'text/javascript')

      head = html_doc.at_css('head')

      if head.nil?
        head = html_doc.create_element('head')
        html_doc.at_css('html').add_child(head)
      end
      head.add_child(script_node)
    end

    # @param [Nokogiri::HTML::Document] html_doc
    #
    def add_auto_refresh_script(html_doc)
      add_file_to_head(:js, html_doc, 'auto_refresh/reloader.coffee')
      add_file_to_head(:js, html_doc, 'auto_refresh/connector.coffee')
      add_file_to_head(:js, html_doc, 'auto_refresh/protocol.coffee')
      add_file_to_head(:js, html_doc, 'auto_refresh/auto_refresh.coffee')
      add_script_to_head(html_doc, 'var auto_refresh = new AutoRefresh(window, console);')
    end

    # @param [Nokogiri::HTML::Document] html_doc
    #
    def add_keyboard_control_script(html_doc, previous_path, next_path)
      add_script_file_to_head(html_doc, 'keyboard_control.coffee',
                              '$previous_path' => previous_path,
                              '$next_path' => next_path)
    end

    # @param [Nokogiri::HTML::Document] html_doc
    #
    def add_file_to_head(type, html_doc, file_path)
      head = html_doc.at_css('head')
      node = case type
             when :style
               html_doc.create_element('link', href: "/server/raw/#{file_path}", rel: 'stylesheet', type: 'text/css')
             when :js
               html_doc.create_element('script', src: "/server/raw/#{file_path}", type: 'text/javascript')
             else
               raise "Unknown file type `#{type}`"
             end

      return if head.css('script, link').any? do |n|
                  (!n['href'].nil? && n['href'] == node['href']) || (!n['src'].nil? && n['src'] == node['src'])
                end

      head.add_child(node)
    end

    # @param [Nokogiri::HTML::Document] html_doc
    # @param [String] key
    # @param [String] value
    #
    def add_meta_to_head(name, content, html_doc, force: false)
      head = html_doc.at_css('head')
      meta = head.at_css("meta[name=\"#{name}\"]")
      return if force == false && !meta.nil?

      meta ||= html_doc.create_element('meta')
      meta['name'] = name
      meta['content'] = content
      head.add_child(meta)
    end

    def self.reload_bookspec
      last_target = target
      Config.instance.bookspec = nil
      self.book = Config.instance.bookspec

      if (new_target = book.target_named(last_target.name))
        self.target = new_target
      else
        self.target = book.targets.first
        _log :ui, "[!] Not found previous target after reloading bookspec file, jumping to first #{target.name}"
      end
    end

    def self._compile_book
      compiler = Epuber::Compiler.new(book, target)
      compiler.compile(build_path)
      self.file_resolver = compiler.file_resolver

      true
    rescue StandardError => e
      self.file_resolver = compiler.file_resolver

      Epuber::UI.error("Compile error: #{e}", location: e)

      false
    end

    def self.compile_book(&completion)
      if !@compilation_thread.nil? && @compilation_thread.status != false
        @compilation_thread.kill
        @compilation_thread = nil
      end

      @compilation_thread = Thread.new do
        result = _compile_book
        completion&.call(result)
      end

      return unless completion.nil?

      @compilation_thread.join
    end

    # @param [String] message
    #
    def self.send_to_clients(message)
      _log :info, "sending message to clients #{message.inspect}"

      sockets.each do |ws|
        ws.send(message)
      end
    end

    # @param [Symbol] type
    def self.notify_clients(type, data = nil)
      _log :info, "Notifying clients with type #{type.inspect}"
      raise "Not known type `#{type}`" unless %i[styles reload compile_start compile_end].include?(type)

      message = {
        name: type,
      }
      message[:data] = data unless data.nil?

      send_to_clients(message.to_json)
    end

    # @param [Array<String>] files_paths
    #
    # @return [Array<String>]
    #
    def self.filter_not_project_files(files_paths)
      return nil if file_resolver.nil?

      files_paths.select { |file| file_resolver.file_with_source_path(file) || book.file_path == file }
    end

    # @param [Array<String>] modified
    # @param [Array<String>] added
    # @param [Array<String>] removed
    #
    def self.changes_detected(modified, added, removed)
      all_changed = (modified + added + removed).uniq.map(&:unicode_normalize)

      reload_bookspec if all_changed.any? { |file| file == book.file_path }

      changed = filter_not_project_files(all_changed) || []
      return if changed.count.zero?

      notify_clients(:compile_start)


      _log :ui, "#{Time.now}  Compiling"
      compile_book do |success|
        unless success
          _log :ui, 'Skipping other steps'
          notify_clients(:compile_end)
          next
        end

        _log :ui, 'Notifying clients'

        # transform all paths to relatives to the server
        changed.map! do |file|
          relative = relative_path_to_book_file(file)
          File.join('', 'book', relative) unless relative.nil?
        end

        # remove nil paths (for example bookspec can't be found so the relative path is nil)
        changed.compact!

        changed_only_styles = changed.all? do |file|
          file.end_with?(*Epuber::Compiler::FileFinders::GROUP_EXTENSIONS[:style])
        end

        if changed.size.positive? && changed_only_styles
          notify_clients(:styles, changed)
        else
          notify_clients(:reload, changed)
        end
      end
    end

    # -------------------------------------------------- #

    # @param [String] path
    #
    def handle_websocket(path)
      _log :ws, "#{path}: start"
      request.websocket do |ws|
        thread = nil

        ws.onopen do
          sockets << ws

          ws.send({ name: :hello }.to_json)

          thread = Thread.new do
            loop do
              sleep(10)
              ws.send({ name: :heartbeat }.to_json)
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

    # @param [String] file_path
    #
    def handle_file(file_path)
      return not_found unless File.exist?(file_path)

      mtime = File.mtime(file_path)
      last_modified(mtime)
      etag(mtime.to_s)
      cache_control :public, :must_revalidate

      case File.extname(file_path)
      when '.styl'
        content_type('text/css')
        body(Stylus.compile(::File.new(file_path)))
      when '.coffee'
        content_type('text/javascript')
        body(CoffeeScript.compile(::File.read(file_path)))
      else
        extname = File.extname(file_path)
        type    = unless Compiler::FileFinders::BINARY_EXTENSIONS.include?(extname)
                    mime_type = MIME::Types.of(file_path).first
                    if mime_type.nil?
                      'text/plain'
                    else
                      content_type
                    end
                  end

        send_file(file_path, type: type, last_modified: mtime)
      end
    end

    # -------------------------------------------------- #

    # @!group Sinatra things

    register Sinatra::Namespace

    enable :sessions
    disable :show_exceptions
    disable :dump_errors
    enable :raise_errors

    set :bind, '0.0.0.0'

    # uncomment following line to enable accessing from remote devices
    # set :port, '8080'

    error do
      ShowExceptions.new(self).call(env)
    end

    not_found do
      [404, 'Epuber: Not found']
    end


    # ----------------------------------
    # @group Home page
    #
    namespace '' do
      get '/?' do
        if request.websocket?
          handle_websocket('/')
        else
          handle_server_bade('book.bade')
        end
      end

      get '/change_target/:target_name' do |target_name|
        selected_target = book.target_named(target_name)

        next [404, 'Target not found'] if selected_target.nil?

        self.target = selected_target
        self.class.compile_book
        redirect '/'
      end
    end

    namespace '/book' do
      get '/*' do
        next handle_websocket("/book/#{params[:splat].first}") if request.websocket?

        path = find_file
        next not_found if path.nil?

        full_path = File.expand_path(path, build_path)

        case File.extname(full_path)
        when '.xhtml'
          content_type :xhtml
          handle_xhtml_file(full_path)
        else
          handle_file(full_path)
        end
      end
    end

    # ------------------------------------------
    # @group TOC
    #
    get '/toc/?' do
      if request.websocket?
        handle_websocket('/toc')
      else
        handle_server_bade('toc.bade')
      end
    end

    # ----------------------------------
    # @group Pretty files
    #
    namespace '/files' do
      get '/?' do
        if request.websocket?
          handle_websocket('/files')
        else
          handle_server_bade('files.bade')
        end
      end

      get '/*' do
        path = find_file
        next not_found if path.nil?

        _log :get, "/files/#{params[:splat].first}: founded file #{path}"

        handle_file(File.expand_path(path, build_path))
      end
    end

    # ----------------------------------
    # @group Raw files

    # Returns file with path or pattern, base_path is epub root
    #
    get '/raw/*' do
      path = find_file
      next not_found if path.nil?

      handle_file(File.expand_path(path, build_path))
    end

    # ----------------------------------
    # @group Server files
    #
    namespace '/server' do
      get '/raw/vendor/bower/:name/*' do |name, rest|
        path = File.join(ThirdParty::Bower.path_to_js(name.to_sym), rest)
        handle_file(path)
      end

      get '/raw/*' do
        file_path = File.expand_path("server/#{params[:splat].first}", File.dirname(__FILE__))
        handle_file(file_path)
      end
    end
  end
end
