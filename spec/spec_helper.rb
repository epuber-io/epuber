require 'coveralls'
Coveralls.wear!

require 'rspec'
require 'fakefs/spec_helpers'


$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'epuber'

require_relative 'matchers/xml'

Epuber::Config.test = true

module FakeFS
  module FileUtils
    def uptodate?(new, old_list)
      return false unless File.exist?(new)
      new_time = File.mtime(new)
      old_list.each do |old|
        if File.exist?(old)
          return false unless new_time > File.mtime(old)
        end
      end
      true
    end
  end
end


RSpec.configure do |c|
  if ENV['SKIP_EXPENSIVE_TESTS'] == 'true'
    c.filter_run_excluding expensive: true
  end
end




def spec_root
  File.dirname(__FILE__)
end

def resolve_file_paths(file)
  # hack lines, because this normally does FileResolver
  if file.respond_to?(:source_path)
    file.abs_source_path = file.source_path
  end

  file.pkg_destination_path = file.destination_path
  file.final_destination_path = file.destination_path
end
