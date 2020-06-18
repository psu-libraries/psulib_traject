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
    access = Traject::MarcExtractor.cached('949m').collect_matching_lines(record) do |field, spec, extractor|
      library_code = extractor.collect_subfields(field, spec).first
      case library_code
      when 'ONLINE'
        'Online'
      when 'ACQ_DSL', 'ACQUISTNS', 'SERIAL-SRV'
        'On Order'
      when 'ZREMOVED', 'XTERNAL'
        next
      else
        resolve_library_code field, LIBRARIES_MAP[library_code]
      end
    end

    access << 'Online' if hathi_access? context
    access.compact!
    access.uniq!
    access.delete 'On Order' if not_only_on_order? access
    access
  end

  # If there is anything other than On Order, we DO NOT include On Order
  def not_only_on_order?(access_data)
    access_data.include?('On Order') && access_data.length > 1
  end

  def resolve_library_code(field, library)
    return 'Other' if library.nil? # Something unexpected
    return 'In the Library' unless field['l'] == 'ON-ORDER'

    'On Order'
  end

  def hathi_access?(context)
    hathitrust_struct = context.output_hash&.dig('hathitrust_struct')
    hathitrust_etas = context.settings['hathi_etas']
    return false unless hathitrust_struct

    hathitrust_etas || (JSON.parse(hathitrust_struct&.first)['access'] == 'allow' && !hathitrust_etas)
  end
end
