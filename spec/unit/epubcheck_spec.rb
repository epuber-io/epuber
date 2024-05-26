# frozen_string_literal: true

require_relative '../spec_helper'
require 'epuber/epubcheck'

module Epuber
  describe Epubcheck do
    it 'parses epubcheck from json' do
      json = load_fixture('epubcheck.json')

      result = described_class._parse_json(json)

      expect(result.problems.size).to eq(15)

      problem = result.problems.first
      expect(problem.level).to eq(:error)
      expect(problem.code).to eq('HTM-004')
      expect(problem.location.path).to eq('OEBPS/CODING_FOR_KIDS_A5bAMAZON_EDITION.html')
      expect(problem.location.lineno).to eq(-1)
      expect(problem.location.column).to eq(-1)
      expect(problem.message).to eq(
        %(Irregular DOCTYPE: found "-//W3C//DTD XHTML 1.1 //EN", expected "<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" \n"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">".),
      )
    end
  end
end
