# encoding: utf-8

require_relative 'lib/epuber'

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
  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency 'mime-types', '~> 2.4'
  spec.add_runtime_dependency 'stylus'
  spec.add_runtime_dependency 'claide', '~> 0.8'
  spec.add_runtime_dependency 'colorize'

  spec.add_development_dependency 'bundler', '~> 1'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'epubcheck'
end
