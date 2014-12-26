require 'rspec'
require 'fileutils'

require_relative '../lib/epuber/main_controller'


describe 'Test project' do
  it 'do something' do
    Dir.chdir('../test_project') {
      FileUtils.rmtree(Epuber::MainController::BASE_PATH)
      FileUtils.remove(Dir.glob('*.epub'))

      system('ruby ../bin/epuber compile')

      system('epubcheck experiment-ibooks.epub')
    }
  end
end

