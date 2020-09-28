# frozen_string_literal: true

# Determines the access status of a record, how patrons are able to acquire an item.
# https://github.com/psu-libraries/psulib_blacklight/wiki/Access-Facet
class MarcAccessFacetProcessor
  LIBRARIES_MAP = Traject::TranslationMap.new('libraries')

  def initialize
    freeze
  end

  # Extract 949m for access facet
  def extract_access_data(record, context)
    access = determine_access_label record

    access << 'Online' if hathi_access? context
    access << 'Open Access' if open_access? record

    access.compact!
    access.uniq!
    access.delete 'On Order' if not_only_on_order? access
    access
  end

  private

  def open_access?(record)
    conditions_on_access_indicate_oa?(record) && link_access_indicates_oa?(record)
  end

  def conditions_on_access_indicate_oa?(record)
    conditions_on_access(record) == 'star'
  end

  def conditions_on_access(record)
    record['506']&.subfields&.select { |s| s.code == '2' }&.first&.value
  end

  def link_access_indicates_oa?(record)
    link_access_status(record) == '0'
  end

  def link_access_status(record)
    record['856']&.subfields&.select { |s| s.code == '7' }&.first&.value
  end

  def determine_access_label(record)
    Traject::MarcExtractor.cached('949m').collect_matching_lines(record) do |field, spec, extractor|
      library_code = extractor.collect_subfields(field, spec).first
      case library_code
      when 'ONLINE'
        'Online'
      when 'ACQ_DSL', 'ACQUISTNS', 'SERIAL-SRV'
        'On Order'
      when 'ZREMOVED', 'XTERNAL'
        next
      else
        other_possibilities field, LIBRARIES_MAP[library_code]
      end
    end
  end

  # If there is anything other than On Order, we DO NOT include On Order
  def not_only_on_order?(access_data)
    access_data.include?('On Order') && access_data.length > 1
  end

  def other_possibilities(field, library)
    return 'Other' if library.nil? # Something unexpected
    return 'On Order' if field['l'] == 'ON-ORDER'

    'In the Library'
  end

  def hathi_access?(context)
    hathitrust_struct = context.output_hash&.dig('hathitrust_struct')
    hathitrust_etas = context.settings['hathi_etas']
    return false unless hathitrust_struct

    hathitrust_etas || JSON.parse(hathitrust_struct&.first)['access'] == 'allow'
  end
end
