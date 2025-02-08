# frozen_string_literal: true

require_relative 'lib/epuber/version'

Gem::Specification.new do |spec|
  spec.name     = 'epuber'
  spec.version  = Epuber::VERSION
  spec.authors  = ['Roman Kříž']
  spec.email    = ['samnung@gmail.com']
  spec.summary  = 'Epuber is simple tool to compile and pack source files into EPUB format.'
  spec.homepage = Epuber::HOME_URL
  spec.license  = 'MIT'
  spec.required_ruby_version = '>= 2.5'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['bin/**/*'] + Dir['lib/**/*'] + %w[epuber.gemspec Gemfile LICENSE.txt README.md]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 6.0', '< 9.0'
  spec.add_dependency 'addressable', '~> 2.7'
  spec.add_dependency 'claide', '~> 1.0'
  spec.add_dependency 'listen', '~> 3.0'
  spec.add_dependency 'mime-types', '~> 3.0'
  spec.add_dependency 'nokogiri', '~> 1.8', '>= 1.8.2'
  spec.add_dependency 'os', '~> 1.0'
  spec.add_dependency 'uuidtools', '~> 2.1'

  spec.add_dependency 'sinatra', '>= 2.0', '< 4.0'
  spec.add_dependency 'sinatra-contrib', '>= 2.0', '< 4.0'
  spec.add_dependency 'sinatra-websocket', '~> 0.3'
  spec.add_dependency 'thin', '~> 1.6'

  spec.add_dependency 'rmagick', '>= 4.2', '< 7.0'
  spec.add_dependency 'rubyzip', '~> 2.3'

  spec.add_dependency 'epubcheck-ruby', '>= 4.0', '< 6.0', '!= 5.2.0.0'

  spec.add_dependency 'bade', '~> 0.3', '>= 0.3.1'
  spec.add_dependency 'coffee-script', '~> 2.4'
  spec.add_dependency 'css_parser', '>= 0.8', '< 2.0'
  spec.add_dependency 'epuber-stylus', '~> 1.1', '>= 1.1.1'
end
