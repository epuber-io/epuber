# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'epuber/version'


Gem::Specification.new do |spec|
  spec.name     = 'epuber'
  spec.version  = Epuber::VERSION
  spec.authors  = ['Roman Kříž']
  spec.email    = ['samnung@gmail.com']
  spec.summary  = 'Epuber is simple tool to compile and pack source files into EPUB format.'
  spec.homepage = Epuber::HOME_URL
  spec.license  = 'MIT'
  spec.required_ruby_version = '>= 2.5'

  spec.files         = Dir['bin/**/*'] + Dir['lib/**/*'] + %w(epuber.gemspec Gemfile LICENSE.txt README.md)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activesupport', '~> 6.0'
  spec.add_runtime_dependency 'addressable', '~> 2.7'
  spec.add_runtime_dependency 'nokogiri', '~> 1.8', '>= 1.8.2'
  spec.add_runtime_dependency 'mime-types', '~> 3.0'
  spec.add_runtime_dependency 'claide', '~> 1.0'
  spec.add_runtime_dependency 'listen', '~> 3.0'
  spec.add_runtime_dependency 'os', '~> 1.0'

  spec.add_runtime_dependency 'sinatra', '~> 2.0'
  spec.add_runtime_dependency 'sinatra-websocket', '~> 0.3'
  spec.add_runtime_dependency 'sinatra-contrib', '~> 2.0'
  spec.add_runtime_dependency 'thin', '~> 1.6'

  spec.add_runtime_dependency 'rmagick', '~> 4.2'
  spec.add_runtime_dependency 'rubyzip', '~> 2.3'

  spec.add_runtime_dependency 'epubcheck-ruby', '~> 4.0'

  spec.add_runtime_dependency 'epuber-stylus', '~> 1.1', '>= 1.1.1'
  spec.add_runtime_dependency 'coffee-script', '~> 2.4'
  spec.add_runtime_dependency 'bade', '~> 0.2.4'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'rubocop', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'fakefs', '~> 1.3'
end
