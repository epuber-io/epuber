# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'epuber/version'


Gem::Specification.new do |spec|
  spec.name     = 'epuber'
  spec.version  = Epuber::VERSION
  spec.authors  = ['Roman Kříž']
  spec.email    = ['samnung@gmail.com']
  spec.summary  = 'Command line tool for easy creating and maintaining ebooks.'
  spec.description = "Command line tool for easy creating and maintaining ebooks.\n"
                     'With support Stylus.'
  spec.homepage = 'http://epuber.io'
  spec.license  = 'Commercial'

  spec.files         = Dir['bin/**/*'] + Dir['lib/**/*'] + %w(epuber.gemspec Gemfile Gemfile.lock LICENSE.txt README.md)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://gem.epuber.io"
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.add_runtime_dependency 'activesupport', '~> 4.2'
  spec.add_runtime_dependency 'nokogiri', '~> 1.6'
  spec.add_runtime_dependency 'mime-types', '~> 2.4'
  spec.add_runtime_dependency 'claide', '~> 0.8'
  spec.add_runtime_dependency 'listen', '~> 3.0'
  spec.add_runtime_dependency 'os', '~> 0.9'

  spec.add_runtime_dependency 'stylus', '~> 1.0'
  spec.add_runtime_dependency 'coffee-script'

  spec.add_runtime_dependency 'sinatra', '~> 1.4'
  spec.add_runtime_dependency 'sinatra-websocket', '~> 0.3'
  spec.add_runtime_dependency 'sinatra-contrib', '~> 1.4'
  spec.add_runtime_dependency 'thin', '~> 1.6'

  spec.add_runtime_dependency 'rmagick', '~> 2.14'

  spec.add_runtime_dependency 'rubyzip', '~> 1.0'

  spec.add_runtime_dependency 'epubcheck', '~> 3.0', '>= 3.0.1'

  spec.add_runtime_dependency 'bade', '0.1.1'

  spec.add_runtime_dependency 'bundler', '~> 1'

  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'rubocop', '~> 0.29'
  spec.add_development_dependency 'rake', '~> 10.4'
end
