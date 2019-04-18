# frozen_string_literal: true

ESTIMATE_TOLERANCE = 15
MIN_YEAR = 500
MAX_YEAR = Time.new.year + 6

# Feed the record to the MarcPubDateProcessor class to find the publication year.
#
# Refactor of Traject::Macros::Marc21Semantics#marc_publication_date as the basic logic but check for 264|*1|c before
# 260c.
def process_publication_date(record)
  return nil unless record.is_a? MARC::Record

  field008 = Traject::MarcExtractor.cached('008').extract(record).first
  marc_date_processor = MarcPubDateProcessor.new(field008)
  pub_date = marc_date_processor.find_date

  if pub_date.nil?
    # Nothing from 008, try 264 and 260
    field264c = Traject::MarcExtractor.cached('264|*1|c', separator: nil).extract(record).first
    field260c = Traject::MarcExtractor.cached('260c', separator: nil).extract(record).first
    pub_date = marc_date_processor.check_elsewhere field264c, field260c
  end

  # Ignore dates below min_year (default 500) or above max_year (this year plus 6 years)
  pub_date && (pub_date > MIN_YEAR || pub_date < MAX_YEAR) ? pub_date : nil
end
