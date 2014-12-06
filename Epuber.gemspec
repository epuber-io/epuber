# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require_relative 'lib/Epuber'

Gem::Specification.new do |spec|
	spec.name        = 'Epuber'
	spec.version     = Epuber::VERSION
	spec.authors     = ['Roman Kříž']
	spec.email       = ['samnung@gmail.com']
	spec.summary     = %q{Command line tool for easy creating ePub files with templates support.}
	spec.homepage    = ''
	spec.license     = 'MIT'

	spec.files         = `git ls-files -z`.split("\x0")
	spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ['lib']

	spec.add_runtime_dependency 'activesupport', '>= 3.2.15'
	spec.add_runtime_dependency 'nokogiri'

	spec.add_development_dependency 'bundler', '~> 1.6'
	spec.add_development_dependency 'rspec'
end
