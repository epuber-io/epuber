require 'rspec'
require 'fileutils'

require_relative '../lib/epuber'


describe 'Test project' do
  it 'do something' do
    Dir.chdir('../test_project') {
      FileUtils.rmtree(Epuber::Command::BASE_PATH)
      FileUtils.remove(Dir.glob('*.epub'))

      system('ruby ../bin/epuber compile --check')

      Dir.glob('*.epub').each { |epub_file|
        system(%{epubcheck "#{epub_file}"})
      }
    }
  end
end

