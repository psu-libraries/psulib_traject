# frozen_string_literal: true

$LOAD_PATH.prepend(Pathname.pwd.join('lib').to_s)

ENV['RUBY_ENVIRONMENT'] ||= 'dev'

require 'pry' if /dev|test/.match?(ENV['RUBY_ENVIRONMENT'])
require 'bundler/setup'
require 'psulib_traject'

extend Traject::Macros::Marc21
extend Traject::Macros::Marc21Semantics
extend PsulibTraject::Macros
extend PsulibTraject::Macros::Subjects
extend PsulibTraject::Macros::SeriesTitle

settings do
  provide 'solr.url', PsulibTraject::SolrManager.new.query_url.to_s
  provide 'log.batch_size', ConfigSettings.log.batch_size
  provide 'solr.version', ConfigSettings.solr.version
  provide 'log.file', ConfigSettings.log.file
  provide 'log.error_file', ConfigSettings.log.error_file
  provide 'solr_writer.commit_on_close', ConfigSettings.solr_writer.commit_on_close
  provide 'reader_class_name', ConfigSettings.reader_class_name
  provide 'commit_timeout', ConfigSettings.commit_timeout
  provide 'hathi_overlap_path', ConfigSettings.hathi_overlap_path

  if RUBY_ENGINE == 'jruby'
    provide 'marc4j_reader.permissive', ConfigSettings.marc4j_reader.permissive
    provide 'marc4j_reader.source_encoding', ConfigSettings.marc4j_reader.source_encoding
    provide 'processing_thread_pool', ConfigSettings.processing_thread_pool
  end
end
ATOZ = ('a'..'z').to_a.join
ATOU = ('a'..'u').to_a.join

ht_overlap = PsulibTraject::HathiOverlapReducer.new(ConfigSettings.hathi_overlap_path)
ht_overlap_hash = ht_overlap.hashify

logger.info RUBY_DESCRIPTION

to_field 'marc_display_ss', serialized_marc(format: 'xml', allow_oversized: true)

to_field 'all_text_timv', extract_all_marc_values do |_r, acc|
  acc.replace [acc.join(' ')] # turn it into a single string
end

# Identifiers
#
## Catkey
to_field 'id', extract_marc('001'), first_only, strip

## ISBN
to_field 'isbn_sim', extract_marc('020az', separator: nil) do |_record, accumulator|
  original = accumulator.dup
  accumulator.map! { |x| StdNum::ISBN.allNormalizedValues(x) }
  accumulator << original
  accumulator.flatten!
  accumulator.uniq!
end

to_field('isbn_valid_ssm', extract_marc('020a', separator: nil)) do |_record, accumulator|
  accumulator.map! { |x| StdNum::ISBN.allNormalizedValues(x) }
  accumulator.flatten!
  accumulator.uniq!
end

to_field 'isbn_ssm', extract_marc('020aqz', separator: ' '), trim_punctuation

## ISSN
to_field 'issn_sim', extract_marc('022a:022l:022m:022y:022z', separator: nil) do |_record, accumulator|
  original = accumulator.dup
  accumulator.map! { |x| StdNum::ISSN.normalize(x) }
  accumulator << original
  accumulator.flatten!
  accumulator.uniq!
end
to_field 'issn_ssm', extract_marc('022a', separator: nil)

# OCLC number
#
## Not sure why didn't end up using the method Traject::Macros::Marc21Semantics::oclcnum
to_field 'oclc_number_ssim', extract_oclc_number

# Deprecated OCLCs
to_field 'deprecated_oclcs_tsim', extract_deprecated_oclcs

# Library of Congress number
to_field 'lccn_ssim', extract_marc('010a'), trim_punctuation

# Special Collections Accessioning Number ("scan")
to_field 'scan_sim', extract_marc('099a')

# Report Numbers
to_field 'report_numbers_ssim', extract_marc('027aq:086a:088aq')

# Title fields
#
## Title Search Fields
to_field 'title_tsim', extract_marc('245a')
to_field 'title_245ab_tsim', extract_marc('245ab'), trim_punctuation
to_field 'title_addl_tsim', extract_marc(%W[
  245abnps
  130#{ATOZ}
  240abcdefgklmnopqrs
  210ab
  222ab
  242abnp
  243abcdefgklmnopqrs
  246abcdefgnp
  247abcdefgnp
].join(':'))
to_field 'title_added_entry_tsim', extract_marc(%w[
  730abcdefgklmnopqrst
  740anp
].join(':'))
to_field 'title_related_tsim', extract_marc(%w[
  505t
  730adfgklmnoprst
  740anp
  760st
  762st
  765st
  767st
  770st
  772st
  773st
  774st
  775st
  776st
  777st
  780st
  785st
  786st
  787st
  790lktmnoprs
  791lktmnoprs
  792lktmnoprs
  793adflktmnoprs
  796lktmnoprs
  797lktmnoprs
  798lktmnoprs
].join(':')), trim_punctuation do |record, accumulator|
  accumulator.each { |value| value.chomp!(' --') } unless record.fields('505').empty?
end

## Title Display Fields
to_field 'title_latin_display_ssm', extract_marc('245abcfghknps', alternate_script: false), trim_punctuation
to_field 'title_vern', extract_marc('245abcfghknps', alternate_script: :only), trim_punctuation
# use vern title as title_display_ssm if exists
# otherwise use latin character title as title_display_ssm
each_record do |_record, context|
  PsulibTraject::Processors::TitleDisplay.new(context).call
end
to_field 'uniform_title_display_ssm', extract_marc('130adfklmnoprs:240adfklmnoprs'), trim_punctuation
to_field 'additional_title_display_ssm', extract_marc('210ab:246iabfgnp:247abcdefgnp'), trim_punctuation
to_field 'related_title_display_ssm', extract_marc('730adfgiklmnoprst3:740anp'), trim_punctuation

## Title Sort Fields
to_field 'title_sort', marc_sortable_title

## Series Titles
to_field 'series_title_tsim', extract_marc('440av:490anpv:830anpv')
to_field 'series_title_strict_tsim', extract_marc('440a:490a:830a'), trim_punctuation
to_field 'series_title_display_ssm', extract_series_title_display

# Author fields
#
## Primary author
to_field 'author_tsim', extract_marc('100aqbcdk:110abcdfgkln:111abcdfgklnpq')

## Additional authors
to_field 'author_addl_tsim', extract_marc('700aqbcdk:710abcdfgkln:711abcdfgklnpq')

## Authors for faceting
to_field 'all_authors_facet', extract_marc('100aqbcdkj:110abcdfgklnj:111abcdfgklnpqj:700aqbcdjk:710abcdfgjkln:711abcdfgjklnpq'), trim_punctuation

# 386a Author Demographics facet
to_field 'author_demo_facet', extract_marc('386a'), trim_punctuation

## Author display
to_field 'author_person_display_ssm', extract_marc('100aqbcdkj'), trim_punctuation
to_field 'author_corp_display_ssm', extract_marc('110abcdfgklnj'), trim_punctuation
to_field 'author_meeting_display_ssm', extract_marc('111abcdfgklnpqj'), trim_punctuation
to_field 'addl_author_display_ssm', extract_marc('700aqbcdjk:710abcdfgjkln:711abcdfgjklnpq'), trim_punctuation

# HathiTrust access
if ht_overlap_hash
  to_field 'ht_access_ss' do |_record, accumulator, context|
    catkey = context.output_hash['id']&.first
    accumulator << ht_overlap_hash[catkey]&.first&.[]('access')
  end
end

## Access facet
access_facet_processor = PsulibTraject::Processors::AccessFacet.new
to_field 'access_facet' do |record, accumulator, context|
  access_facet = access_facet_processor.extract_access_data record, context
  accumulator.replace(access_facet) unless !access_facet || access_facet.empty?
end

# Formats
to_field 'format' do |record, accumulator|
  formats = PsulibTraject::Processors::Format.call(record: record)
  accumulator.replace(formats)
end

# Media Types Facet
to_field 'media_type_facet' do |record, accumulator, context|
  access_facet = context.output_hash['access_facet']
  media_types = PsulibTraject::Processors::MediaType.call(record: record, access_facet: access_facet)
  accumulator.replace(media_types)
end

# Publication fields
#
## Publisher/Manufacturer for search
to_field 'publisher_manufacturer_tsim', extract_marc('260b:264|*1|b:260f:264|*3|b'), trim_punctuation

## Publication year facet (sidebar)
to_field 'pub_date_itsi', process_publication_date

## Publication fields for display
to_field 'copyright_display_ssm', extract_marc('264|*4|c')
to_field 'cartographic_mathematical_data_ssm', extract_marc('255abcdefg')
to_field 'other_edition_ssm', extract_marc('775|0*|iabcdefghkmnor')
to_field 'collection_facet', extract_marc('793a')
to_field 'publication_display_ssm', extract_marc('260abcefg3:264|*1|abc3') # display in search results
to_field 'overall_imprint_display_ssm', extract_marc('260abcefg3:264|*0|abc3:264|*1|abc3:264|*2|abc3:264|*3|abc3') # display on single item page
to_field 'edition_display_ssm', extract_marc('250ab3')
# processes display fields to help format vernacular display
each_record do |_record, context|
  PsulibTraject::Processors::PubDisplay.new('publication', context).call
  PsulibTraject::Processors::PubDisplay.new('overall_imprint', context).call
  PsulibTraject::Processors::PubDisplay.new('edition', context).call
end

## Publication fields for Illiad and Aeon
to_field 'pub_date_illiad_ssm', extract_marc('260c:264|*1|c'), trim_punctuation
to_field 'publisher_name_ssm', extract_marc('260b:264|*1|b'), trim_punctuation
to_field 'publication_place_ssm', extract_marc('260a:264|*1|a'), trim_punctuation

to_field 'language_facet', marc_languages('008[35-37]')

# Subject fields
#
## Primary subject
to_field 'subject_tsim', extract_marc('600abcdfklmnopqrtvxyz:610abfklmnoprstvxyz:611abcdefgklnpqstvxyz:630adfgklmnoprstvxyz:647acdg:648a:650abcd:651a:653a:654ab')

## Other Subject
to_field 'subject_other_display_ssm', extract_marc('653a'), strip, split(';'), trim_punctuation

## Additional subject fields
to_field 'subject_addl_tsim', extract_marc('600vxyz:610vxyz:611vxyz:630vxyz:647vxyz:648vxyz:650vxyz:651vxyz:654vyz')

## Subject display
#
## For hierarchical subject display and linking
hierarchy_fields = '650|*0|abcdvxyz:650|*2|abcdvxyz:650|*1|abcdvxyz:650|*3|abcdvxyz:650|*6|abcdvxyz:650|*7|abcdvxyz:600abcdfklmnopqrtvxyz:610abfklmnoprstvxyz:611abcdefgklnpqstvxyz:630adfgklmnoprstvxyz:647acdgvxyz:648avxyz:651avxyz'
to_field 'subject_display_ssm', process_subject_hierarchy(hierarchy_fields)
to_field 'subject_facet', process_subject_hierarchy(hierarchy_fields)

## Subject facet (sidebar)
to_field 'subject_topic_facet', process_subject_topic_facet('650|*0|aa:650|*0|x:650|*1|aa:650|*1|x:651|*0|a:651|*0|x:600abcdtq:610abt:610x:611abt:611x')

## Subject browse facet
to_field 'subject_browse_facet', process_subject_browse_facet(
  standard_fields: '600|*0|abcd:610|*0|abcd:611|*0|abcd:630|*0|avxyz:647|*0|avxyz:650|*0|abcdgvxyz:650|*1|abcdgvxyz:650|*2|abcdgvxyz:650|*3|abcdgvxyz:651|*0|agvxyz',
  pst_fields: '650|*7|abcdgvxyz'
)

# Genre Fields
#
## Main genre
to_field 'genre_tsim', extract_marc('650|*0|v:655|*0|abcvxyz:655|*7|abcvxyz')

## Genre facet (sidebar)
to_field 'genre_facet', process_genre('650|*0|v:655|*0|abcvxyz:655|*7|abcvxyz')

## Genre display
to_field 'genre_display_ssm', process_genre('655|*0|abcvxyz:655|*7|abcvxyz')

## For genre links
to_field 'genre_full_facet', process_genre('650|*0|v:655|*0|abcvxyz:655|*7|abcvxyz')

# Call Number fields
to_field 'lc_1letter_facet', extract_marc('050a') do |_record, accumulator|
  next unless accumulator.any?

  first_letter = accumulator[0].lstrip.slice(0, 1)
  letters = PsulibTraject.regex_to_extract_data_from_a_string accumulator[0], /([[:alpha:]])*/
  unless Traject::TranslationMap.new('callnumber_map')[letters].nil?
    lc1letter = Traject::TranslationMap.new('callnumber_map')[first_letter]
  end
  accumulator.replace [lc1letter]
end

to_field 'lc_rest_facet', extract_marc('050a') do |_record, accumulator|
  next unless accumulator.any?

  letters = PsulibTraject.regex_to_extract_data_from_a_string accumulator[0], /([[:alpha:]])*/
  lc_rest = Traject::TranslationMap.new('callnumber_map')[letters]
  accumulator.replace [lc_rest]
end

# Call Number Browse
#
## Determines a base call number from the record's holdings and creates forward and reverse shelfkeys for LC, LCPER and DEWEY
each_record do |record, context|
  call_numbers = PsulibTraject::Holdings.call(record: record, context: context)
  next if call_numbers.empty?

  call_numbers.each do |call_number|
    context.add_output(call_number.solr_field, call_number.value)
    context.add_output(call_number.shelfkey_field, call_number.normalized_shelfkey)
  end

  context.add_output('keymap_struct', *call_numbers.map(&:keymap).to_json)
end

# Summary Holdings
#
# Builds a json struct of summary holdings for applicable records
to_field 'summary_holdings_struct' do |record, accumulator|
  summary_holdings = PsulibTraject::Processors::SummaryHoldings.call(record: record)
  accumulator << summary_holdings.to_json unless summary_holdings.empty?
end

# Material Characteristics
#
## 300 / 340 Physical description / physical medium
to_field 'phys_desc_ssm', extract_marc('300abcefg3:340abcdefhijkmno3'), trim_punctuation

## 380 Form of work
to_field 'form_work_ssm', extract_marc('380a'), trim_punctuation

## Work other characteristics

## 310 / 321 Current publication frequency / former publication frequency
to_field 'frequency_ssm', extract_marc('310ab:321ab')

## 385 Audience
to_field 'audience_ssm' do |record, accumulator|
  next unless record['385']

  audience_fields = record.fields('385')
  audience_fields.each do |field|
    qualifier = ''
    audience_value = ''

    field.each do |subfield|
      case subfield.code
      when 'm'
        qualifier = "#{subfield.value}: "
      when 'a', '3' # TODO: find a record with a subfield 3
        audience_value = subfield.value
      end
    end
    accumulator << (qualifier + audience_value)
  end
end

## A/v and print music works

## 306 Duration
to_field 'duration_ssm', extract_marc('306a')

## 344 Sound characteristics
to_field 'sound_ssm', extract_marc('344abcdefgh3')

## 383 Numeric designation of musical work
to_field 'music_numerical_ssm' do |record, accumulator|
  semi_colon_set = []
  no_semi_colon_set = []

  record.fields('383').each do |field|
    field.map do |subfield|
      next if subfield.value.empty?

      case subfield.code
      when 'a', 'b', 'c', 'd'
        semi_colon_set << subfield.value
      when 'e'
        no_semi_colon_set << subfield.value
      end
    end

    accumulator << semi_colon_set.join('; ')
    accumulator.concat no_semi_colon_set
    accumulator.reject!(&:empty?)
  end
end

## 348 Format of notated music
to_field 'music_format_ssm', extract_marc('348a3')

## 384  Musical key
to_field 'music_key_ssm', extract_marc('384a3')

## 382 Medium of performance
to_field 'performance_ssm', extract_marc('382abdenprst3')

## 346 Video characteristics
to_field 'video_file_ssm', extract_marc('346ab3')

## Digital files

## 347 Digital file characteristics
to_field 'digital_file_ssm', extract_marc('347abcdef3')

# URL fields

# Unless subfield z and 3 (Public note and Materials specified) tell us this isn't a fulltext URL OR if 0 is the second
# indicator.
to_field 'full_links_struct', extract_link_data
to_field 'partial_links_struct', extract_link_data(link_type: 'partial')
to_field 'suppl_links_struct', extract_link_data(link_type: 'suppl')

## Notes fields
#
# 500 - Note
to_field 'general_note_ssm', extract_marc('5003a:5903a')

# 501 - "With"
to_field 'with_note_ssm', extract_marc('501a')

# 502 - Dissertation Note
to_field 'dissertation_note_ssm', extract_marc('502abcdgo')

# 504 - Bibliography Note
to_field 'bibliography_note_ssm', extract_marc('504ab')

# 505 - Table of Contents
to_field 'toc_ssim', extract_marc('505agrt')

# 506 - Restrictions on Access
to_field 'restrictions_access_note_ssm', extract_marc('506abcdefu')

# 507 - scale note for graphic material
to_field 'scale_graphic_material_note_ssm', extract_marc('507ab')

# 508 - Creation/Production Credits Note
to_field 'creation_production_credits_ssm', extract_marc('508a')

# 510 - Citation/References Note
to_field 'citation_references_note_ssm', extract_marc('510| *|3abcux')
to_field 'indexed_by_note_ssm', extract_marc('510|0*|3abcux:510|1*|3abcux')
to_field 'selectively_indexed_by_note_ssm', extract_marc('510|2*|3abcux')
to_field 'references_note_ssm', extract_marc('510|3*|3abcux:510|4*|3abcux')

# 511 - Participant/Performer Note
to_field 'participant_performer_ssm', extract_marc('511a')

# 513 - Type of Report and Period Covered Note
to_field 'type_report_period_note_ssm', extract_marc('513ab')

# 515 - Special Numbering
to_field 'special_numbering_ssm', extract_marc('515a')

# 516 - Type of File/Data
to_field 'file_data_type_ssm', extract_marc('516a')

# 518 - Data/Place of Event
to_field 'date_place_event_note_ssm', extract_marc('518adop3')

# 520 - Notes Summary
to_field 'notes_summary_ssim', extract_marc('520ab')

# 521 - Audience
to_field 'audience_notes_ssm', extract_marc('521| *|3ab:521|8*|3ab:521|3*|3ab:521|4*|3ab')
to_field 'reading_grade_ssm', extract_marc('521|0*|3ab')
to_field 'interest_age_ssm', extract_marc('521|1*|3ab')
to_field 'interest_grade_ssm', extract_marc('521|2*|3ab')

# 522 - Geographic Coverage
to_field 'geographic_coverage_ssm', extract_marc('522a')

# 524 - Preferred Citation
to_field 'preferred_citation_ssm', extract_marc('5243a')

# 525 - Supplement Note
to_field 'supplement_ssm', extract_marc('525a')

# 530 - Other Forms
to_field 'other_forms_ssm', extract_marc('530abc3')

# 532 - Dates of Publication and/or Sequential Designation
to_field 'dates_of_pub_ssim', extract_marc('362a')

# 533 - Reproduction Note
to_field 'reproduction_note_ssm', extract_marc('533abcdefmn3')

# 534 - Original Version
to_field 'original_version_note_ssm', extract_marc('534pabcefklmnotxz3')

# 535 - location of original or duplicates (indicators indicate which)
to_field 'originals_loc_ssm', extract_marc('535|1*|3abcdg')
to_field 'dup_loc_ssm', extract_marc('535|2*|3abcdg')

# 536 - Funding Information
to_field 'funding_information_ssm', extract_marc('536abcdefgh')

# 538 - Technical Details
to_field 'technical_details_ssm', extract_marc('538aiu3')

# 540 - Terms of Use and Reproduction
to_field 'terms_use_reproduction_ssm', extract_marc('540abcdu3')

# 541 - Source of Acquisition
to_field 'source_aquisition_ssm', extract_marc('541| *|abcdefhn3:541|1*|abcdefhn3')

# 542 - Copyright Note
to_field 'copyright_status_ssm', extract_marc('542| *|abcdefghijklmnopqrsu3:542|1*|abcdefghijklmnopqrsu3')

# 544 - Associated Materials
to_field 'associated_materials_ssm', extract_marc('544|0*|abcden3')
to_field 'related_materials_ssm', extract_marc('544|1*|abcden3:544| *|abcden3')

# 545 - Biographical/Historical Note
to_field 'administrative_history_note_ssm', extract_marc('545| *|abu:545|1*|abu')
to_field 'biographical_sketch_note_ssm', extract_marc('545|0*|abu')

# 546 - Language Note
to_field 'language_note_ssm', extract_marc('546ab3')

# 547 - Title Varies
to_field 'former_title_ssm', extract_marc('547a')

# 550 - Issuing Body
to_field 'issuing_ssm', extract_marc('550a')

# 555 - index/finding aid note (indicators vary)
to_field 'index_note_ssm', extract_marc('555| *|abcd3:555|8*|abcd3e')
to_field 'finding_aid_note_ssm', extract_marc('555|0*|abcd3')

# 556 - Documentation Information
to_field 'documentation_info_note_ssm', extract_marc('556az')

# 561 - Provenance
to_field 'provenance_note_ssm', extract_marc('561| *|au3:561|1*|au3')

# 562 - Version/Copy ID
to_field 'version_copy_id_note_ssm', extract_marc('562abcde3')

# 563 - Binding Information
to_field 'binding_information_ssm', extract_marc('563au3')

# 567 - Methodology Note
to_field 'methodology_ssm', extract_marc('567ab')

# 580 - Complexity Note
to_field 'complexity_ssm', extract_marc('580a')

# 583 - Action Note
to_field 'action_note_ssm', extract_marc('583| *|abcdefhijklnouz3:583|1*|abcdefhijklnouz3')

# 585 - Exhibitions
to_field 'exhibitions_ssm', extract_marc('585a3')

# 586 - Awards
to_field 'awards_ssm', extract_marc('586a3')

# Bound with notes
to_field 'bound_with_struct' do |record, accumulator|
  bound_in_format_map = Traject::TranslationMap.new('bound_in')

  record.fields('591').each do |field|
    bound_with_arr = field.map do |subfield|
      case subfield.code
      when 'a'
        { bound_title: subfield.value }
      when 'c'
        { bound_catkey: subfield.value }
      when 't'
        { bound_format: bound_in_format_map.translate_array([subfield.value])[0] }
      when 'n'
        { bound_callnumber: subfield.value }
      end
    end

    accumulator << bound_with_arr.compact.reduce(:merge).to_json
  end
end

# 699a Thesis Department
to_field 'thesis_dept_display_ssm', extract_marc('699a'), trim_punctuation, include_psu_theses_only
to_field 'thesis_dept_facet', extract_marc('699a'), trim_punctuation, include_psu_theses_only

# 773 - "Part Of"
to_field 'part_of_ssm', extract_marc('773|0*|abdghiklmnopqrstuwxyz34', separator: nil), trim_punctuation

# Place
#
# UP Library facet
to_field 'up_library_facet', extract_marc('949m'), translation_map('up_libraries')
# Campus facet
to_field 'campus_facet', extract_marc('949m'), translation_map('campuses')
# All libraries (in psulib_blacklight this is used only in advanced search)
to_field 'library_facet', extract_marc('949m'), translation_map('libraries')
# All locations (in psulib_blacklight this is used only in advanced search)
to_field 'location_facet', extract_marc('949l'), exclude_locations, translation_map('locations')

# 993 - Endowment Information
to_field 'endowment_note_ssim', extract_marc('993an')
to_field 'endowment_note_display_ssm', extract_marc('993n')

# 995 - Dedication Information
to_field 'dedication_ssim', extract_marc('995abcd3n')

# Serials fields
#
# Preceding and Succeeding Entries display
to_field 'serials_continues_display_ssim', extract_marc('780|00|t:780|02|t')
to_field 'serials_continued_by_display_ssim', extract_marc('785|00|t:785|02|t')
to_field 'serials_continues_in_part_display_ssim', extract_marc('780|01|t:780|03|t')
to_field 'serials_continued_in_part_by_display_ssim', extract_marc('785|01|t:785|03|t')
to_field 'serials_formed_from_display_ssim', extract_marc('780|04|t')
to_field 'serials_absorbs_display_ssim', extract_marc('780|05|t')
to_field 'serials_absorbed_by_display_ssim', extract_marc('785|04|t')
to_field 'serials_absorbs_in_part_display_ssim', extract_marc('780|06|t')
to_field 'serials_absorbed_in_part_by_display_ssim', extract_marc('785|05|t')
to_field 'serials_separated_from_display_ssim', extract_marc('780|07|t')
to_field 'serials_split_into_display_ssim', extract_marc('785|06|t')
to_field 'serials_merged_to_form_display_ssim', extract_marc('785|07|t')
to_field 'serials_changed_back_to_display_ssim', extract_marc('785|08|t')

# 799a - Sublocation
# From our catalog experts: "The data in this field corresponds to "collections" within Special Collections, and
# the 799 data lets their staff know which shelf (or range of shelves) to check for the call number in question.
to_field 'sublocation_ssm', extract_marc('799a')

# IIIF Manifest url
#
# 856|*1|u if subfield y is IIIF Manifest
to_field 'iiif_manifest_ssim', extract_iiif_manifest
