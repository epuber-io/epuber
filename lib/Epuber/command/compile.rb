require_relative '../command'

module Epuber
  class Command
    class Compile < Command
      self.summary = 'Compile targets into epub.'
      self.arguments = [
        CLAide::Argument.new('TARGETS', false, true)
      ]
    end
  end
end
