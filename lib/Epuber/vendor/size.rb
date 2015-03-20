
module Epuber
  class Size
    # @return [Numeric]
    #
    attr_reader :width

    # @return [Numeric]
    #
    attr_reader :height

    # @param [Numeric] width
    # @param [Numeric] height
    #
    def initialize(width, height)
      @width = width
      @height = height
    end
  end
end
