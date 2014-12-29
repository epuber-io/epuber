require 'rubygems'

module Epuber
  require_relative 'epuber/version'

  autoload :MainController, 'epuber/main_controller'

  require_relative 'epuber/command'
end
