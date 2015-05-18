# encoding: utf-8

module Epuber
  require_relative 'epuber/version'

  require 'bundler/setup'

  autoload :Book, 'epuber/book'
  autoload :Command, 'epuber/command'
  autoload :Compiler, 'epuber/compiler'
  autoload :Config, 'epuber/config'
  autoload :UI, 'epuber/user_interface'
  autoload :UserInterface, 'epuber/user_interface'
end
