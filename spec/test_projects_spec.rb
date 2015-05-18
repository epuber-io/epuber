# encoding: utf-8

require_relative 'spec_helper'

require 'rspec'
require 'fileutils'

describe 'Test project' do
  it 'do something' do
    Dir.chdir('test_project') do
      # FileUtils.rmtree(Epuber::Config::WORKING_PATH)
      # FileUtils.remove(Dir.glob('*.epub'))

      Epuber::Command.run(%w(compile --check --write))
      Epuber::Command.run(%w(compile --release))
    end
  end
end
