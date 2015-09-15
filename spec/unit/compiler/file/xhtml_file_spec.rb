# encoding: utf-8

require_relative '../../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_types/xhtml_file'


module Epuber
  class Compiler
    module FileTypes



      describe XHTMLFile do
        include FakeFS::SpecHelpers

      end



    end
  end
end
