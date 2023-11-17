# frozen_string_literal: true

transform :result_text_xhtml_string do |transformer|
  transformer.replace_all(/( |\(|\[| |„|>)(k|s|v|u|o|z|K|S|V|U|O|Z|I|A) /, '\1\2 ', multiple_times: true)

  transformer.replace_all(/\b([0-9½¼¾]+) ((?:[0-9]+|mm|cm|mg|kg|USD|°C|g|oz|ml|lb|fl oz)\b|min\.|%)/, '\1 \2',
                          multiple_times: true)
end

transform :source_text_file do |transformer|
  transformer.replace_all(/( |\(|\[| |„|>)(k|s|v|u|o|z|K|S|V|U|O|Z|I|A) /, '\1\2 ', multiple_times: true)
end
