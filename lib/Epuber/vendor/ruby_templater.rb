# encoding: utf-8

# rubocop:disable Lint/Eval

module Epuber
  class RubyTemplater
    # @param string [String]
    # @param variables [Hash]
    #
    def self.render(string, variables = {})
      require_relative 'hash_binding'
      hash_binding = HashBinding.new(variables)
      b = hash_binding.get_binding
      eval_string = %(%(#{string}))
      eval(eval_string, b)
    end

    # @param file_path [String] path to template
    # @param variables [Hash]
    #
    def self.render_file(file_path, variables = {})
      require_relative 'hash_binding'
      hash_binding = HashBinding.new(variables)
      b = hash_binding.get_binding
      string = ::File.read(file_path)
      eval_string = %(%(#{string}))
      eval(eval_string, b, file_path)
    end
  end
end

# rubocop:enable Lint/Eval
