require 'rspec'
require 'fakefs/spec_helpers'


$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'epuber'

require_relative 'matchers/xml'


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
