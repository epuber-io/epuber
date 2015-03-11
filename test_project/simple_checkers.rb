
check :result_text_xhtml_string, :always do |checker, text|
  checker.should_not_find(/Jason Fried/, 'Found Jason Fried, kill him!')
end

check :result_text_xhtml_string, :before_release do |checker, text|
  puts ':release'
end
