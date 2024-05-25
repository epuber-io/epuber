# frozen_string_literal: true

require 'epuber/epubcheck'

module Epuber
  describe Epubcheck do
    it 'parses epubcheck output' do
      line = 'ERROR(RSC-005): sladkobol2-ibooks-debug.epub/OEBPS/text/copyright.xhtml(23,35): Error while parsing file: Duplicate ID "123"' # rubocop:disable Layout/LineLength

      result = described_class._parse_line(line)

      expect(result.level).to eq(:error)
      expect(result.code).to eq('RSC-005')
      expect(result.location.path).to eq('sladkobol2-ibooks-debug.epub/OEBPS/text/copyright.xhtml')
      expect(result.location.lineno).to eq(23)
      expect(result.location.column).to eq(35)
      expect(result.message).to eq('Error while parsing file: Duplicate ID "123"')
    end
  end
end
