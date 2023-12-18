# frozen_string_literal: true

require_relative '../spec_helper'

require 'rspec'
require 'fileutils'

describe 'Test project' do # rubocop:disable RSpec/DescribeClass
  it 'do something', :expensive do
    Dir.chdir('test_project') do
      # FileUtils.rmtree(Epuber::Config::WORKING_PATH)
      # FileUtils.remove(Dir.glob('*.epub'))

      expect do
        Epuber::Command.run(%w[build --check --write --verbose])
        Epuber::Command.run(%w[build --release --verbose])
      end.to output(/.*/).to_stdout_from_any_process
    end
  end
end
