
begin
  require 'unicode_normalize'
rescue LoadError
  # silently fail

  require 'active_support/multibyte/unicode'

  class String
    unless respond_to?(:unicode_normalize)
      def unicode_normalize
        ActiveSupport::Multibyte::Unicode.normalize(self)
      end
    end
  end
end
