# encoding: utf-8

# Most of this code is taken from github.com/CocoaPods/Core/blob/master/lib/cocoapods-core/vendor/version.rb

module Epuber
  class Version
    include Comparable

    VERSION_RE ||= /\A[0-9]+(\.[0-9a-zA-Z]+)*\z/

    # True if the +version+ string matches RubyGems' requirements.
    #
    def self.correct?(version)
      version.to_s =~ VERSION_RE
    end

    attr_reader :version, :segments


    # @param [String, Numeric] version input primitive value for version
    #
    def initialize(version)
      unless self.class.correct?(version)
        raise StandardError, "Malformed version number string #{version}"
      end

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
      "#{segments.join('.')}"
    end

    # Compares this version with +other+ returning -1, 0, or 1 if the
    # other version is larger, the same, or smaller than this
    # one.
    #
    # @return [Numeric]
    #
    def <=>(other)
      return unless other.is_a?(Version) || other.is_a?(String) || other.is_a?(Float) || other.is_a?(Fixnum)
      other = other.is_a?(Version) ? other : Version.new(other)

      return 0 if @version == other.version

      lhsegments = segments
      rhsegments = other.segments

      lhsize = lhsegments.size
      rhsize = rhsegments.size
      limit  = (lhsize > rhsize ? lhsize : rhsize) - 1

      i = 0

      while i <= limit
        lhs, rhs = lhsegments[i] || 0, rhsegments[i] || 0
        i += 1

        next      if lhs == rhs
        return -1 if String  == lhs && Numeric == rhs
        return  1 if Numeric == lhs && String  == rhs

        return lhs <=> rhs
      end

      0
    end
  end
end
