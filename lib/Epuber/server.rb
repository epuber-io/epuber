# encoding: utf-8

require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra-websocket'

require 'nokogiri'
require 'listen'

require 'active_support'

require_relative 'vendor/hash_binding'

require 'bade'
require 'stylus'
require 'coffee-script'

require_relative 'third_party/bower'


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

    BINARY_FILES_EXTNAMES = %w(.png .jpeg .jpg .otf .ttf)

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
    def self.run!(book, target)
      self.book = book
      self.target = target

      start_listening_if_needed

      super()
    end

    def initialize
      super
      _log :ui, 'Init compile'
      self.class.compile_book
    end

    def self.start_listening_if_needed
      return unless self.listener.nil?

      self.listener = Listen.to(Config.instance.project_path, debug: true) do |modified, added, removed|
        begin
          changes_detected(modified, added, removed)
        rescue => e
          # print error, do not send error further, listener will die otherwise
          $stderr.puts e
          $stderr.puts e.backtrace
        end
      end

      listener.ignore(%r{\.idea})
      listener.ignore(%r{#{Config.instance.working_path}})
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


    # @param level [Symbol]
    # @param message [String]
    #
    # @return nil
    #
    def self._log(level, message)
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

    def _log(level, message)
      self.class._log(level, message)
    end


    # -------------------------------------------------- #

    # @!group Helpers

    # @param pattern [String]
    #
    # @return [String] path to file
    #
    def find_file(pattern = params[:splat].first, source_path: build_path)
      paths = nil

      exact_path = ::File.join(source_path, pattern)
      if ::File.file?(exact_path)
        return exact_path.sub(::File.join(source_path, ''), '')
      end

      Dir.chdir(source_path) do
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

    # @param [String] path
    #
    # @return [String]
    #
    def self.relative_path_to_book_file(path)
      file = file_resolver.file_with_source_path(path)
      abs_path = File.join(build_path, '')
      file.destination_path.sub(abs_path, '')
    end

    # @param html_doc [Nokogiri::HTML::Document]
    # @param context_path [String]
    # @param css_selector [String]
    # @param attribute_name [String]
    #
    def fix_links(html_doc, context_path, css_selector, attribute_name)
      img_nodes = html_doc.css(css_selector)
      img_nodes.each do |node|
        src = node[attribute_name]

        unless src.nil?
          abs_path      = File.expand_path(src, File.join(build_path, File.dirname(context_path)))
          relative_path = abs_path.sub(File.expand_path(build_path), '')

          node[attribute_name] = File.join('', 'raw', relative_path.to_s)
        end
      end
    end

    def add_script_file_to_head(html_doc, file_name, *args)
      source = File.read(File.expand_path("server/#{file_name}", File.dirname(__FILE__)))

      if File.extname(file_name) == '.coffee'
        source = CoffeeScript.compile(source)
      end

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

    # @param html_doc [Nokogiri::HTML::Document]
    # @param script_text [String]
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

    # @param html_doc [Nokogiri::HTML::Document]
    #
    def add_auto_refresh_script(html_doc)
      add_file_to_head(:js, html_doc, 'auto_refresh/reloader.coffee')
      add_file_to_head(:js, html_doc, 'auto_refresh/connector.coffee')
      add_file_to_head(:js, html_doc, 'auto_refresh/protocol.coffee')
      add_file_to_head(:js, html_doc, 'auto_refresh/auto_refresh.coffee')
      add_script_file_to_head(html_doc, 'auto_refresh/auto_refresh.js') do |script|
        bonjour_name = "#{`hostname`.chomp}.local"

        script.gsub!('GSUB_PORT', settings.port.to_s)
        script.gsub!('GSUB_IP_ADDRESS', request.ip)
        script.gsub!('GSUB_BONJOUR_NAME', bonjour_name)

        script
      end
    end

    # @param html_doc [Nokogiri::HTML::Document]
    #
    def add_keyboard_control_script(html_doc, previous_path, next_path)
      add_script_file_to_head(html_doc, 'keyboard_control.coffee',
                              '$previous_path' => previous_path,
                              '$next_path' => next_path)
    end

    # @param html_doc [Nokogiri::HTML::Document]
    #
    def add_file_to_head(type, html_doc, file_path)
      head = html_doc.at_css('head')
      node = case type
             when :style
               html_doc.create_element('link',  href: "/server/raw/#{file_path}" ,rel: 'stylesheet', type: 'text/css')
             when :js
               html_doc.create_element('script', src: "/server/raw/#{file_path}", type: 'text/javascript')
             else
               raise "Unknown file type `#{type}`"
             end

      return if head.css('script, link').any? { |n| (!n['href'].nil? && n['href'] == node['href']) || (!n['src'].nil? && n['src'] == node['src']) }

      head.add_child(node)
    end

    def self.reload_bookspec
      Config.instance.bookspec = nil
      self.book = Config.instance.bookspec
    end

    def self.compile_book
      compiler = Epuber::Compiler.new(book, target)
      compiler.compile(build_path)
      self.spine = compiler.file_resolver.files_of(:spine)
      self.file_resolver = compiler.file_resolver
    end

    # @param message [String]
    #
    def self.send_to_clients(message)
      _log :info, "sending message to clients #{message.inspect}"

      sockets.each do |ws|
        ws.send(message)
      end
    end

    # @param type [Symbol]
    def self.notify_clients(type, data = nil)
      _log :info, "Notifying clients with type #{type.inspect}"
      raise "Not known type `#{type}`" unless [:styles, :reload, :compile_start, :compile_end].include?(type)
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

    # @param _modified [Array<String>]
    # @param _added [Array<String>]
    # @param _removed [Array<String>]
    #
    def self.changes_detected(_modified, _added, _removed)
      all_changed = (_modified + _added).uniq
      changed = filter_not_project_files(all_changed) || []
      return if changed.count == 0

      notify_clients(:compile_start)

      reload_bookspec if all_changed.any? { |file| file == book.file_path }

      _log :ui, 'Compiling'
      compile_book

      _log :ui, 'Notifying clients'

      changed.map! { |file| File.join('', 'raw', relative_path_to_book_file(file)) }

      if changed.all? { |file| file.end_with?(*Epuber::Compiler::FileResolver::GROUP_EXTENSIONS[:style]) }
        notify_clients(:styles, changed)
      else
        notify_clients(:reload, changed)
      end
    end

    def self.render_bade(name)
      source_path = File.expand_path("server/pages/#{name}", File.dirname(__FILE__))

      renderer = Bade::Renderer.from_file(source_path)
                               .with_locals(book: book, target: target, file_resolver: file_resolver)

      result = renderer.render(new_line: '', indent: '')

      [200, result]
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

          ws.send({name: :hello}.to_json)

          thread = Thread.new do
            loop do
              sleep(10)
              ws.send({name: :heartbeat}.to_json)
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
      return not_found unless File.exists?(file_path)

      last_modified(File.mtime(file_path))

      case File.extname(file_path)
      when '.styl'
        content_type('text/css')
        body(Stylus.compile(::File.new(file_path)))
      when '.coffee'
        content_type('text/javascript')
        body(CoffeeScript.compile(::File.read(file_path)))
      else
        extname = File.extname(file_path)
        type    = unless BINARY_FILES_EXTNAMES.include?(extname)
                    mime_type = MIME::Types.of(file_path).first
                    if mime_type.nil?
                      'text/plain'
                    else
                      content_type
                    end
                  end

        send_file(file_path, type: type)
      end
    end

    # -------------------------------------------------- #

    # @!group Sinatra things

    register Sinatra::Namespace

    enable :logging
    enable :sessions
    disable :show_exceptions
    disable :dump_errors
    enable :raise_errors

    set :bind, '0.0.0.0'

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
        self.class.render_bade('book.bade')
      end

      get '/change_target/:target_name' do |target_name|
        selected_target = book.target_named(target_name)

        next [404, 'Target not found'] if selected_target.nil?

        self.target = selected_target
        self.class.compile_book
        redirect '/'
      end
    end

    # ------------------------------------------
    # @group TOC
    #
    namespace '/toc' do
      get '/?' do
        self.class.render_bade('toc.bade')
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

        add_file_to_head(:js, html_doc, 'vendor/bower/jquery/jquery.min.js')
        add_file_to_head(:js, html_doc, 'vendor/bower/spin/spin.js')
        add_file_to_head(:js, html_doc, 'vendor/bower/cookies/cookies.min.js')
        add_file_to_head(:js, html_doc, 'vendor/bower/uri/URI.min.js')
        add_file_to_head(:js, html_doc, 'vendor/bower/keymaster/keymaster.js')
        add_file_to_head(:style, html_doc, 'book_content.styl')

        add_file_to_head(:js, html_doc, 'support.coffee')
        add_auto_refresh_script(html_doc)


        current_index = spine.index { |file| file_resolver.relative_path_from_package_root(file) == path }
        previous_path = file_resolver.relative_path_from_package_root(spine_file_at(current_index - 1))
        next_path     = file_resolver.relative_path_from_package_root(spine_file_at(current_index + 1))
        add_keyboard_control_script(html_doc, previous_path, next_path)

        [200, html_doc.to_html]
      end
    end

    # ----------------------------------
    # @group Pretty files
    #
    namespace '/files' do
      get '/?' do
        self.class.render_bade('files.bade')
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
