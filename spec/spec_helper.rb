# frozen_string_literal: true

require 'rspec'
require 'fakefs/spec_helpers'


$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'epuber'

require_relative 'matchers/xml'

Epuber::Config.test = true

module FakeFS
  module FileUtils
    def uptodate?(new, old_list)
      return false unless File.exist?(new)

      new_time = File.mtime(new)
      old_list.each do |old|
        return false if File.exist?(old) && new_time <= File.mtime(old)
      end
      true
    end
  end
end


RSpec.configure do |c|
  c.filter_run_excluding expensive: true if ENV['SKIP_EXPENSIVE_TESTS'] == 'true'

  c.before do
    Epuber::Config.class_eval { @instance = nil }
    Epuber::Config.instance
  end
end




def spec_root
  File.dirname(__FILE__)
end

def resolve_file_paths(file)
  # HACK: lines, because this normally does FileResolver
  file.abs_source_path = file.source_path if file.respond_to?(:source_path)

  file.pkg_destination_path = file.destination_path
  file.final_destination_path = file.destination_path
end

def write_file(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
end

def load_xhtml(path)
  Epuber::Compiler::XHTMLProcessor.xml_document_from_string(File.read(path), path)
end
