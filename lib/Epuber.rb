# encoding: utf-8

module Epuber
  VERSION = '0.1.0'

  require 'bundler/setup'
  Bundler.setup

  autoload :Book, 'epuber/book'
  autoload :Command, 'epuber/command'
  autoload :Compiler, 'epuber/compiler'
  autoload :Config, 'epuber/config'
end
