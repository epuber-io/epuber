module Epuber
  module ThirdParty
    class Bower
      class << self
        JS_COMPONENTS = {
          jquery:    'jquery/dist/',
          cookies:   'cookies-js/dist/',
          uri:       'uri.js/src/',
          spin:      'spin.js/',
          keymaster: 'keymaster/',
        }

        def path_to_js(component)
          path = JS_COMPONENTS[component]
          raise "Not found component #{component}" if path.nil?

          File.expand_path("bower/bower_components/#{path}", File.dirname(__FILE__))
        end
      end
    end
  end
end
