# frozen_string_literal: true

require_relative '../../../spec_helper'

require 'epuber/book'
require 'epuber/compiler'
require 'epuber/compiler/file_types/xhtml_file'


module Epuber
  class Compiler
    module FileTypes
      describe XHTMLFile do
        include FakeFS::SpecHelpers

        before do
          @book = Book.new

          @ctx = CompilationContext.new(@book, @book.default_target)
          @ctx.file_resolver = FileResolver.new('/', '/.build')
        end

        it 'handles ugly file with all xml bullshit lines' do
          source = <<~XML
            <?xml version="1.0" encoding="UTF-8" standalone="no"?>
            <!DOCTYPE html>
            <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
              <head>
                <title/>
                <meta charset="utf-8"/>
              </head>
              <body id="Nastaveni-mysli_001-az-304-1">
                <div class="_idGenObjectStyleOverride-1">
                  <p>Some bullshit content</p>
                </div>
              </body>
            </html>
          XML

          File.write('some_file.xhtml', source)

          file = described_class.new('some_file.xhtml')
          file.destination_path = 'some_file_dest.xhtml'
          resolve_file_paths(file)

          file.process(@ctx)

          expect(File.read('some_file_dest.xhtml')).to eq source
        end

        it 'handles xml header on next line' do
          source = <<~XML

            <?xml version="1.0" encoding="UTF-8" standalone="no"?>
            <!DOCTYPE html>
            <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
              <head>
                <title/>
                <meta charset="utf-8"/>
              </head>
              <body id="Nastaveni-mysli_001-az-304-1">
                <div class="_idGenObjectStyleOverride-1">
                  <p>Some bullshit content</p>
                </div>
              </body>
            </html>
          XML
          File.write('some_file.xhtml', source)

          file = described_class.new('some_file.xhtml')
          file.destination_path = 'some_file_dest.xhtml'
          resolve_file_paths(file)

          # Act
          file.process(@ctx)

          # Assert
          message = UI.logger.messages.last
          expect(message.level).to eq :warning
          expect(message.message).to eq 'XML header must be at the beginning of document'
          expect(message.location.path).to eq 'some_file.xhtml'
          expect(message.location.lineno).to eq 1

          expect(File.read('some_file_dest.xhtml')).to eq source.lstrip
        end

        it 'prints warning when XML is not alright while building release build' do
          source = <<~XML
            <body>
              <p>abc
            </body>
          XML

          File.write('some_file.xhtml', source)

          file = described_class.new('some_file.xhtml')
          file.destination_path = 'some_file_dest.xhtml'
          resolve_file_paths(file)

          @ctx.release_build = true
          file.compilation_context = @ctx

          expected_output1 = <<~TEXT.rstrip
            some_file.xhtml:3 column: 8 --- 3:8: FATAL: Opening and ending tag mismatch: p line 2 and body
              </body>
                     ^
            some_file.xhtml:4 column: 8 --- 4:8: FATAL: Opening and ending tag mismatch: body line 1 and root
              </body>
                     ^
          TEXT

          expected_output2 = <<~TEXT.rstrip
            #{expected_output1}
            some_file.xhtml:4 column: 8 --- 4:8: FATAL: Premature end of data in tag root line 1
              </body>
                     ^
          TEXT

          # Act
          file.process(@ctx)

          # Assert
          expect(UI.logger.formatted_messages).to match(expected_output1).or match(expected_output2)
        end

        it 'handles space in link' do
          source = <<~XML
            <body>
              <p><a href="http://hbr.org/ear/an/612017-PDF-EN G">abc</a></p>
            </body>
          XML

          expected_output = <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
              <head>
                <title/>
                <meta charset="utf-8"/>
              </head>
              <body>
              <p><a href="http://hbr.org/ear/an/612017-PDF-EN%20G">abc</a></p>
            </body>
            </html>
          XML

          File.write('some_file.xhtml', source)

          file = described_class.new('some_file.xhtml')
          file.destination_path = 'some_file_dest.xhtml'
          resolve_file_paths(file)

          @ctx.release_build = true
          file.compilation_context = @ctx

          file.process(@ctx)

          expect(File.read('some_file_dest.xhtml')).to eq expected_output
        end

        it 'handles unicode in link' do
          source = <<~XML
            <body>
              <p><a href="http://hbr.org/ear/an/612017–123">abc</a></p>
            </body>
          XML

          expected_output = <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
              <head>
                <title/>
                <meta charset="utf-8"/>
              </head>
              <body>
              <p><a href="http://hbr.org/ear/an/612017%E2%80%93123">abc</a></p>
            </body>
            </html>
          XML

          File.write('some_file.xhtml', source)

          file = described_class.new('some_file.xhtml')
          file.destination_path = 'some_file_dest.xhtml'
          resolve_file_paths(file)

          @ctx.release_build = true
          file.compilation_context = @ctx

          file.process(@ctx)

          expect(File.read('some_file_dest.xhtml')).to eq expected_output
        end

        it 'can parse global ids' do
          source = <<~XML
            <body>
              <p id="$some_id">abc</p>
              <p id="other_id">abc</p>
            </body>
          XML

          File.write('some_file.xhtml', source)

          file = described_class.new('some_file.xhtml')
          file.destination_path = 'some_file_dest.xhtml'
          resolve_file_paths(file)

          @ctx.release_build = true
          file.compilation_context = @ctx

          file.process(@ctx)

          expect(file.global_ids).to eq(['some_id'])
        end

        it 'can parse global links' do
          source = <<~XML
            <body>
              <a href="$some_id">abc</a>
              <a href="#other_id">abc</a>
            </body>
          XML

          File.write('some_file.xhtml', source)

          file = described_class.new('some_file.xhtml')
          file.destination_path = 'some_file_dest.xhtml'
          resolve_file_paths(file)

          @ctx.release_build = true
          file.compilation_context = @ctx

          file.process(@ctx)

          expect(file.global_links).to eq(['some_id'])
        end
      end
    end
  end
end
