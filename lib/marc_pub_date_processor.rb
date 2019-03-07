# frozen_string_literal: true

# For determining the single three to four digit publication year.
#
# If 008 represents a date range, will take the midpoint of the range, only if range is smaller than estimate_tolerance,
# default 15 years.
#
# @param field008 [String] The 008 field from the Marc record
# @return nil if field008 is not set
# @return [Integer] if the field's date can be found, the year found
class MarcPubDateProcessor
  attr_accessor :field008, :date_type, :date1, :date2

  def initialize(field008)
    @field008 = field008
    return unless @field008 && @field008.length >= 11

    @date_type = field008.slice(6)
    @date1_str = field008.slice(7, 4)
    @date2_str = field008.length > 15 ? field008.slice(11, 4) : ''
  end

  # Based on the date_type, return the proper value.
  def find_date
    return nil if @date_type.nil? || @date_type == 'n'

    case @date_type
    when 'p', 'r'
      # Reissue/reprint/re-recording, etc.
      date_str = @date2_str.to_i != 0 ? @date2_str : @date1_str
      resolve_date date_str
    when 'q'
      # Questionable
      resolve_range
    else
      # Default case, just resolve the first date.
      resolve_date @date1_str
    end
  end

  # For when we are dealing with ranges.
  def resolve_range
    # Make unknown digits at the beginning or end of range
    date1 = @date1_str.tr('u', '0').to_i
    date2 = @date2_str.tr('u', '9').to_i

    # Do we have a range we can use?
    return nil unless (date2 > date1) && ((date2 - date1) <= ESTIMATE_TOLERANCE)

    (date2 + date1) / 2
  end

  # Resolve single date u's means range, find midpoint and check tolerance
  def resolve_date(date_str)
    u_count = date_str.count 'u'
    # Replace unknown digits with 0.
    date = date_str.tr('u', '0').to_i
    if u_count.positive? && date != 0
      delta = 10**u_count # 10^u_count, exponent
      date + (delta / 2) if delta <= ESTIMATE_TOLERANCE
    elsif date != 0
      date
    end
  end

  # In case looking at the 008 failed, check 264|*1|c then 260c for a date.
  def check_elsewhere(field264c, field260c)
    date = field264c || field260c
    # Take the first four digits.
    match = /(\d{4})/.match(date)
    match[1].to_i if match
  end
end
