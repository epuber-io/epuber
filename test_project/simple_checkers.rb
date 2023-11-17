# frozen_string_literal: true

# encoding utf-8

check :result_text_xhtml_string do |checker|
  checker.should_not_contain(/(̌|́)/i, 'Contains strange diacritic characters')

  checker.should_not_contain(/[-–—][-–—]+/i, 'Contains redundant dashes')

  checker.should_not_contain(/( | )(,|\.|;|:)( | )/i, 'Contains alone `(,|.|;|:)`')

  checker.should_not_contain(/ -( |,|\.)/i, 'Contains alone ` -( |,|.)`')
end
