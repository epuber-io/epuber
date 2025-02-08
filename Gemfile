# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in Epuber.gemspec
gemspec

# dev
gem 'fakefs', '>= 1.3', '< 3.0' # 2.0.0 is not compatible with Ruby 2.5
gem 'rake', '~> 13.0'
gem 'rspec', '~> 3.2'
gem 'rubocop', '~> 1.14'

# VSCode plugins
gem 'ruby-lsp', require: false

group :dev, optional: true do
  gem 'rubocop-rspec', '~> 3.0', require: false
end
