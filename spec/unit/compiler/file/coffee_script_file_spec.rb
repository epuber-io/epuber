# frozen_string_literal: true

require_relative '../../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_types/coffee_script_file'


module Epuber
  class Compiler
    module FileTypes
      describe CoffeeScriptFile do
        include_context 'with temp dir'

        let(:ctx) do
          book = Book.new

          ctx = CompilationContext.new(book, book.default_target)
          ctx.file_resolver = FileResolver.new(temp_dir, File.join(temp_dir, '/.build'))

          ctx
        end

        it 'handles ugly file with all xml bullshit lines' do
          source = <<~COFFEE
            math =
              root: Math.sqrt
              square: square
              cube: (x) -> x * square x
          COFFEE

          source_path = File.join(temp_dir, 'some_file.coffee')
          dest_path = File.join(temp_dir, 'some_file.js')

          File.write(source_path, source)

          file = described_class.new(source_path)
          file.destination_path = dest_path
          resolve_file_paths(file)

          file.compilation_context = ctx
          file.process(ctx)

          expected_content = <<~JS
            (function() {
              var math;

              math = {
                root: Math.sqrt,
                square: square,
                cube: function(x) {
                  return x * square(x);
                }
              };

            }).call(this);
          JS

          expect(File.read(dest_path)).to eq expected_content
        end
      end
    end
  end
end
