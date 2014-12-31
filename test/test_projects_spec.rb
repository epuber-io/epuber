# encoding: utf-8

require_relative 'helpers/spec_helper'

require 'rspec'
require 'fileutils'

require_relative '../lib/epuber'

describe 'Test project' do
  it 'do something' do
    Dir.chdir('test_project') do
      FileUtils.rmtree(Epuber::Command::BASE_PATH)
      FileUtils.remove(Dir.glob('*.epub'))

      system('ruby ../bin/epuber compile --check')
    end
  end
end
