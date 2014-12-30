require 'rubygems'

module Epuber
  require_relative 'epuber/version'

  autoload :Compiler, 'epuber/compiler'

  require_relative 'epuber/command'
end
