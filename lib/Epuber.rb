# encoding: utf-8

module Epuber
  require_relative 'epuber/version'

  autoload :Compiler, 'epuber/compiler'

  require_relative 'epuber/command'
  require_relative 'epuber/config'
end
