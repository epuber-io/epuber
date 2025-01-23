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

  it 'can build project from text subfolder', :expensive do
    FileUtils.remove(Dir.glob('test_project/*.epub'))

    current_dir = Dir.pwd
    Dir.chdir('test_project/text')

    try do
      expect do
        Epuber::Command.run(%w[build ibooks])
      end.to output(/.*/).to_stdout_from_any_process
    ensure
      Dir.chdir(current_dir)
    end

    expect(File).to exist('test_project/prace_na_dalku5-ibooks-debug.epub')
  end
end
