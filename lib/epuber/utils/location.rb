# frozen_string_literal: true

module Epuber
  Location = Struct.new(:path, :lineno, :column, keyword_init: true) do
    # !@attribute [r] path
    #   @return [String] path to file

    # !@attribute [r] lineno
    #   @return [Integer, nil] line number

    # !@attribute [r] column
    #   @return [Integer, nil] column number
  end
end
