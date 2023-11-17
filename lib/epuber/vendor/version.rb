# frozen_string_literal: true

# Most of this code is taken from github.com/CocoaPods/Core/blob/master/lib/cocoapods-core/vendor/version.rb

def is_number(other)
  other.is_a?(Numeric) || other.is_a?(Integer) || other.is_a?(Float)
end

module Epuber
  class Version
    include Comparable

    VERSION_RE ||= /\A[0-9]+(\.[0-9a-zA-Z]+)*\z/.freeze

    # True if the +version+ string matches RubyGems' requirements.
    #
    def self.correct?(version)
      version.to_s =~ VERSION_RE
    end

    attr_reader :version, :segments


    # @param [String, Numeric] version input primitive value for version
    #
    def initialize(version)
      raise StandardError, "Malformed version number string #{version}" unless self.class.correct?(version)

      @version = version.to_s.strip
    end

    # @return [Array<Numeric>]
    #
    def segments
      @segments ||= @version.scan(/[0-9]+|[a-z]+/i).map do |s|
        /^\d+$/ =~ s ? s.to_i : s
      end
    end

    # @return [String]
    #
    def to_s
      segments.join('.').to_s
    end

    # Compares this version with +other+ returning -1, 0, or 1 if the
    # other version is larger, the same, or smaller than this
    # one.
    #
    # @return [Numeric]
    #
    def <=>(other)
      return unless other.is_a?(Version) || other.is_a?(String) || other.is_a?(Float) || other.is_a?(Integer)

      other = other.is_a?(Version) ? other : Version.new(other)

      return 0 if @version == other.version

      lhsegments = segments
      rhsegments = other.segments

      lhsize = lhsegments.size
      rhsize = rhsegments.size
      limit  = (lhsize > rhsize ? lhsize : rhsize) - 1

      i = 0

      while i <= limit
        lhs = lhsegments[i] || 0
        rhs = rhsegments[i] || 0
        i += 1

        next      if lhs == rhs
        return -1 if lhs.is_a?(String) && is_number(rhs)
        return  1 if is_number(lhs) && rhs.is_a?(String)

        return lhs <=> rhs
      end

      0
    end
  end
end
