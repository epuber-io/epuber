
transform :result_text_xhtml_string, :always do |transformer, text|
  transformer.replace_all(/David/, 'Daaaaavid')

  transformer.replace_all(/Heinemeier/) do |match|
    'Heineemeeieer'
  end
end
