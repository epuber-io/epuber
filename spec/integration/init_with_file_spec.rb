# frozen_string_literal: true

require_relative '../spec_helper'

module Epuber
  describe 'init (with file)' do
    include_context 'with temp dir'

    it 'can init project with file' do
      Epuber::Command.run(%w[from-file] + [File.join(__dir__, '..', 'fixtures', 'childrens-media-query.epub')])
    end
  end
end
