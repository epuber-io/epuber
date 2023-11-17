# frozen_string_literal: true

class Thread
  class Backtrace
    class Location
      def hash
        to_s.hash
      end

      def ==(other)
        to_s == other.to_s
      end
    end
  end
end
