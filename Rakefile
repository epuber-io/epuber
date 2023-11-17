# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec



desc 'Shortcut for bower in correct location'
task 'bower_update' do
  Dir.chdir('lib/epuber/third_party/bower') do
    sh 'bower update'
  end
end
