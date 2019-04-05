# frozen_string_literal: true

# Determines the access status of a record, how patrons are able to acquire an item.
class MarcAccessFacetProcessor
  attr_reader :record

  def initialize(record)
    @record = record
  end

  # Extract 949m for access facet
  def extract_access_data
    return unless record.fields('949').any?

    access_data = []
    libraries_map = Traject::TranslationMap.new('libraries')

    Traject::MarcExtractor.cached('949m').collect_matching_lines(record) do |field, spec, extractor|
      library_code = extractor.collect_subfields(field, spec).first
      access_data << case library_code
                     when 'ONLINE'
                       'Online'
                     when 'ACQ_DSL', 'ACQUISTNS', 'SERIAL-SRV'
                       'On Order'
                     when 'ZREMOVED', 'XTERNAL'
                       next
                     else
                       resolve_library_code(field, libraries_map.translate_array([library_code])[0])
                     end
    end
    access_data.compact!
    access_data.uniq!
    access_data.delete('On Order') if not_only_on_order?(access_data)
    access_data
  end

  # If there is anything other than On Order, we DO NOT include On Order
  def not_only_on_order?(access_data)
    access_data.include?('On Order') && (access_data.length > 1)
  end

  def resolve_library_code(field, library)
    return 'Other' if library.nil?

    if !field['l'].nil? && field['l'] == 'ON-ORDER'
      'On Order'
    else
      'In the Library'
    end
  end
end
