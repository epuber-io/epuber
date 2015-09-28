# encoding: utf-8

require 'nokogiri'

module Epuber
  class Server
    def handle_xhtml_file(file_path)
      html_doc = Nokogiri::XML(File.open(file_path))

      add_file_to_head(:js, html_doc, 'vendor/bower/jquery/jquery.min.js')
      add_file_to_head(:js, html_doc, 'vendor/bower/spin/spin.js')
      add_file_to_head(:js, html_doc, 'vendor/bower/cookies/cookies.min.js')
      add_file_to_head(:js, html_doc, 'vendor/bower/uri/URI.min.js')
      add_file_to_head(:js, html_doc, 'vendor/bower/keymaster/keymaster.js')
      add_file_to_head(:style, html_doc, 'book_content.styl')

      add_file_to_head(:js, html_doc, 'support.coffee')
      add_auto_refresh_script(html_doc)

      unless file_resolver.nil?
        current_index = file_resolver.spine_files.index { |file| file.final_destination_path == file_path }

        unless current_index.nil?
          previous_path = spine_file_at(current_index - 1).try(:pkg_destination_path)
          next_path     = spine_file_at(current_index + 1).try(:pkg_destination_path)
          add_keyboard_control_script(html_doc, previous_path, next_path)
        end
      end

      [200, html_doc.to_html]
    end
  end
end
