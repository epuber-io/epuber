# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'epuber'


Gem::Specification.new do |spec|
  spec.name     = 'epuber'
  spec.version  = Epuber::VERSION
  spec.authors  = ['Roman Kříž']
  spec.email    = ['samnung@gmail.com']
  spec.summary  = 'Command line tool for easy creating ePub files with templates support.'
  spec.homepage = ''
  spec.license  = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activesupport', '>= 3.2.15'
  spec.add_runtime_dependency 'nokogiri', '~> 1.6'
  spec.add_runtime_dependency 'mime-types', '~> 2.4'
  spec.add_runtime_dependency 'stylus'
  spec.add_runtime_dependency 'claide', '~> 0.8'
  spec.add_runtime_dependency 'colorize', '~> 0.7'
  spec.add_runtime_dependency 'listen', '~> 2.9'

  spec.add_runtime_dependency 'sinatra', '~> 1.4'
  spec.add_runtime_dependency 'sinatra-websocket', '~> 0.3'
  spec.add_runtime_dependency 'sinatra-contrib', '~> 1.4'
  spec.add_runtime_dependency 'thin', '~> 1.6'

  spec.add_runtime_dependency 'rmagick', '2.13.2'

  spec.add_runtime_dependency 'rubyzip', '~> 1.0'

  spec.add_runtime_dependency 'epubcheck', '>= 3.0.1'

  spec.add_development_dependency 'bundler', '~> 1'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
