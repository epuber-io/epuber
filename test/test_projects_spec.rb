# encoding: utf-8

require_relative 'spec_helper'

require 'rspec'
require 'fileutils'

require_relative '../lib/epuber'

describe 'Test project' do
  it 'do something' do
    Dir.chdir('../test_project') do
      # FileUtils.rmtree(Epuber::Config::WORKING_PATH)
      # FileUtils.remove(Dir.glob('*.epub'))

      system('ruby ../bin/epuber compile --check')
    end
  end
end
