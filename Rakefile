
require 'rubygems'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

Rake::Task[:release].clear
Rake::Task['install:local'].clear


helper = Bundler::GemHelper.instance
gemspec = helper.gemspec
gem_path = File.expand_path("pkg/#{gemspec.name}-#{gemspec.version}.gem", helper.base)


desc 'Push to our geminabox server'
task :push => [:build] do
  sh "gem inabox #{gem_path}"
end

desc 'Push to our geminabox server, !!! but overrides gems with same version !!!'
task 'push-force' => [:build] do
  sh "gem inabox #{gem_path} -o"
end
