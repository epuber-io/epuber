
require_relative 'main_controller/opf'


module Epuber
  class MainController
    include OPF

    # @return [Book]
    #
    attr_accessor :book
  end
end
