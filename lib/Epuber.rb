# encoding: utf-8

module Epuber
  VERSION = '0.2.1'

  require 'bundler/setup'

  autoload :Book, 'epuber/book'
  autoload :Command, 'epuber/command'
  autoload :Compiler, 'epuber/compiler'
  autoload :Config, 'epuber/config'
end
