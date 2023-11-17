# frozen_string_literal: true

require 'nokogiri'

module Epuber
  class Server
    # @param [String] file_path  absolute path to xhtml file
    #
    # @return [(Fixnum, String)]
    #
    def handle_xhtml_file(file_path)
      html_doc = Nokogiri::XML(File.open(file_path))

      add_file_to_head(:js, html_doc, 'vendor/bower/jquery/jquery.min.js')
      add_file_to_head(:js, html_doc, 'vendor/bower/spin/spin.js')
      add_file_to_head(:js, html_doc, 'vendor/bower/cookies/cookies.min.js')
      add_file_to_head(:js, html_doc, 'vendor/bower/uri/URI.min.js')
      add_file_to_head(:js, html_doc, 'vendor/bower/keymaster/keymaster.js')
      add_file_to_head(:style, html_doc, 'book_content.styl')

      add_file_to_head(:js, html_doc, 'support.coffee')
      add_meta_to_head(:viewport, 'width=device-width, initial-scale=1.0', html_doc)
      add_auto_refresh_script(html_doc)

      unless file_resolver.nil?
        current_index = file_resolver.spine_files.index { |file| file.final_destination_path == file_path }

        unless current_index.nil?
          previous_path = spine_file_at(current_index - 1).try(:pkg_destination_path)
          next_path     = spine_file_at(current_index + 1).try(:pkg_destination_path)
          add_keyboard_control_script(html_doc, previous_path, next_path)
        end
      end

      [200, html_doc.to_xhtml]
    end

    # @param [String] file_name  name of the file located in ./pages/
    #
    # @return [(Fixnum, String)]
    #
    def handle_server_bade(file_name)
      handle_bade(File.expand_path("pages/#{file_name}", File.dirname(__FILE__)))
    end

    # @param [String] file_path  path to bade file to render
    #
    # @return [(Fixnum, String)]
    #
    def handle_bade(file_path)
      [200, self.class.render_bade(file_path)]
    rescue StandardError => e
      env['sinatra.error'] = e
      ShowExceptions.new(self).call(env)
    end

    # @param [String] file_path  path to bade file to render
    #
    # @return [String]
    #
    def self.render_bade(file_path)
      renderer = Bade::Renderer.from_file(file_path)
                               .with_locals(book: book, target: target, file_resolver: file_resolver)

      renderer.render(new_line: '', indent: '')
    end
  end
end
