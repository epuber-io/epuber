# frozen_string_literal: true

class MatchData
  # @return [Array<String>]
  #
  def pre_match_lines
    @pre_match_lines ||= pre_match.split(/\r?\n/)
  end

  # @return [Array<String>]
  #
  def post_match_lines
    @post_match_lines ||= post_match.split(/\r?\n/)
  end

  # @return [Fixnum]
  #
  def line_number
    n = pre_match_lines.length
    n += 1 if n.zero? # it can't be zero, this happens only when the match is at the beginning of file or string
    n
  end

  # @return [Fixnum]
  #
  def line_index
    pre_match_lines.length - 1
  end

  # @return [String]
  #
  def matched_line
    (pre_match_lines.last || '') + matched_string + (post_match_lines.first || '')
  end

  # @return [String]
  #
  def matched_string
    self[0]
  end
end
