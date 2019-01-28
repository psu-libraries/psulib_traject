$LOAD_PATH << File.expand_path('../', __dir__)

require 'bundler/setup'
require 'library_stdnums'
require 'traject'
is_jruby = RUBY_ENGINE == 'jruby'
require 'traject/marc4j_reader' if is_jruby
require 'traject/macros/marc21_semantics'
require 'traject/macros/marc_format_classifier'
require_relative './psulib_marc'

extend Traject::Macros::Marc21
extend Traject::Macros::Marc21Semantics
extend Traject::Macros::MarcFormats

Marc21 = Traject::Macros::Marc21
MarcExtractor = Traject::MarcExtractor

ATOZ = ('a'..'z').to_a.join('')
ATOU = ('a'..'u').to_a.join('')

settings do
  provide 'solr.url', 'http://localhost:8983/solr/blacklight-core'
  provide 'log.batch_size', 100_000
  provide 'solr.version', '7.4.0'
  provide 'log.file', 'log/traject.log'
  provide 'log.error_file', 'log/traject_error.log'
  provide 'solr_writer.commit_on_close', 'true'

  if is_jruby
    provide 'reader_class_name', 'Traject::Marc4JReader'
    provide 'marc4j_reader.permissive', true
    provide 'marc4j_reader.source_encoding', 'UTF-8'
    # defaults to 1 less than the number of processors detected on your machine
    # provide 'processing_thread_pool', 7
  end
end

logger.info RUBY_DESCRIPTION

to_field 'id', extract_marc('001', first: true)

to_field 'marc_display_ss', serialized_marc(format: 'xml', allow_oversized: true)

to_field 'all_text_timv', extract_all_marc_values do |_r, acc|
  acc.replace [acc.join(' ')] # turn it into a single string
end

to_field 'language_facet_ssim', marc_languages('008[35-37]:041a:041d:')
to_field 'format', marc_formats

to_field 'isbn_ssim', extract_marc('020a', separator: nil) do |_rec, acc|
  orig = acc.dup
  acc.map! { |x| StdNum::ISBN.allNormalizedValues(x) }
  acc << orig
  acc.flatten!
  acc.uniq!
end

# Title fields
#
# 245 - main title
# 130 / 240 / 730 - uniform title (a standardized form of the title with different intensities)
# 210 - abbreviated title
# 222 - key title
# 242 - translation of title by cataloging agency
# 246 - sub/alternate titles
# 247 - previous titles
# 740 - uncontrolled/alternate title
#
## Title Search Fields
to_field 'title_tsim', extract_marc('245a')
to_field 'title_245ab_tsim', extract_marc('245ab', trim_punctuation: true)
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
  799alktmnoprs
].join(':'), trim_punctuation: true) do |record, accumulator|
  accumulator.each { |value| value.chomp!(' --') } unless record.fields('505').empty?
end

## Title Display Fields
to_field 'title_latin_display_ssm', extract_marc('245abcfgknps', alternate_script: false, trim_punctuation: true)
to_field 'title_vern', extract_marc('245abcfgknps', alternate_script: :only, trim_punctuation: true)
# use vern title as title_display_ssm if exists
# otherwise use latin character title as title_display_ssm
each_record do |_record, context|
  title_latin = context.output_hash['title_latin_display_ssm']
  title_vern = context.output_hash['title_vern']
  if title_vern.nil?
    context.output_hash['title_display_ssm'] = title_latin
    # remove duplicate latin title
    context.output_hash.delete('title_latin_display_ssm')
  else
    context.output_hash['title_display_ssm'] = title_vern
    # remove duplicate vern title
    context.output_hash.delete('title_vern')
  end
end
to_field 'uniform_title_display_ssm', extract_marc('130adfklmnoprs:240adfklmnoprs:730ai', trim_punctuation: true)
to_field 'additional_title_display_ssm', extract_marc('210ab:246iabfgnp:247abcdefgnp', trim_punctuation: true)
to_field 'related_title_display_ssm', extract_marc('730adfgiklmnoprst3:740anp', trim_punctuation: true)

## Title Sort Fields
to_field 'title_ssort', marc_sortable_title

# Author fields
## Primary author
to_field 'author_tsim', extract_marc('100aqbcdk:110abcdfgkln:111abcdfgklnpq')

## Additional authors
to_field 'author_addl_tsim', extract_marc('700aqbcdk:710abcdfgkln:711abcdfgklnpq')

## Authors for faceting
to_field 'all_authors_facet_ssim', extract_marc('100aqbcdkj:110abcdfgklnj:111abcdfgklnpqj:700aqbcdjk:710abcdfgjkln:711abcdfgjklnpq', trim_punctuation: true)

## Author display
to_field 'author_person_display_ssm', extract_marc('100aqbcdkj', trim_punctuation: true)
to_field 'author_corp_display_ssm', extract_marc('110abcdfgklnj', trim_punctuation: true)
to_field 'author_meeting_display_ssm', extract_marc('111abcdfgklnpqj', trim_punctuation: true)
to_field 'addl_author_display_ssm', extract_marc('700aqbcdjk:710abcdfgjkln:711abcdfgjklnpq', trim_punctuation: true)

## Author sorting field
to_field 'author_ssort', marc_sortable_author

# Subject field(s):
## Primary subject
to_field 'subject_tsim', extract_marc('600abcdfklmnopqrtvxyz:610abfklmnoprstvxyz:611abcdefgklnpqstvxyz:630adfgklmnoprstvxyz:647acdg:648a:650abcd:651a:653a:654ab')

## Additional subject fields
to_field 'subject_addl_tsim', extract_marc('600vxyz:610vxyz:611vxyz:630vxyz:647vxyz:648vxyz:650vxyz:651vxyz:654vyz')

## Subject display
hierarchy_fields = '650|*0|abcdvxyz:650|*2|abcdvxyz:650|*1|abcdvxyz:650|*3|abcdvxyz:650|*6|abcdvxyz:650|*7|abcdvxyz:600abcdfklmnopqrtvxyz:610abfklmnoprstvxyz:611abcdefgklnpqstvxyz:630adfgklmnoprstvxyz:647acdgvxyz:648avxyz:651avxyz'
to_field 'subject_display_ssm' do |record, accumulator|
  subjects = process_hierarchy(record, hierarchy_fields)
  accumulator.replace(subjects)
  accumulator.compact!
  accumulator.uniq!
end

## For hierarchical subject display
to_field 'subject_facet' do |record, accumulator|
  subjects = process_hierarchy(record, hierarchy_fields)
  accumulator.replace(subjects)
  accumulator.compact!
  accumulator.uniq!
end

## Subject facet (sidebar)
to_field 'subject_topic_facet_ssim' do |record, accumulator|
  subjects = process_subject_topic_facet(record, '650|*0|aa:650|*0|x:650|*1|aa:650|*1|x:651|*0|a:651|*0|x:600abcdtq:610abt:610x:611abt:611x')
  accumulator.replace(subjects)
  accumulator.compact!
  accumulator.uniq!
end

# Publication fields
## Publisher/Manufacturer for search
to_field 'publisher_manufacturer_tsim', extract_marc('260b:264|*1|b:260f:264|*3|b', trim_punctuation: true)
to_field 'pub_date_ssim', marc_publication_date

## Publication fields for display
to_field 'publication_display_ssm', extract_marc('260abcefg3:264|*1|abc3') # display in search results
to_field 'overall_imprint_display_ssm', extract_marc('260abcefg3:264|*0|abc3:264|*1|abc3:264|*2|abc3:264|*3|abc3') # display on single item page
to_field 'copyright_display_ssm', extract_marc('264|*4|c')
to_field 'edition_display_ssm', extract_marc('250ab3')

# Series fields
#
# Series Titles
#
# Series titles can cause some confusion, as they may contain keywords which aren't necessarily related to the series.
# For example, "Penguin History of Britain" will return in a title search for "Penguin" if it's part of the title search.
#
# 490a - the title of a series.
# 440a - deprecated same as 490a. We still have a lot of these, though, so if we index 490, we should index 440.
#
# Note: 400/410/411 subfield t were deprecated but we still have indexing set up for them
to_field 'series_title_tsim', extract_marc('440anpv:490av')
to_field 'series_title_display_ssm', extract_marc('490avlx3:440anpvx', alternate_script: false, trim_punctuation: true)

# Call Number fields
to_field 'lc_callnum_display_ssm', extract_marc('050ab', first: true)
to_field 'lc_1letter_facet_sim', extract_marc('050ab', first: true, translation_map: 'callnumber_map') do |_rec, acc|
  # Just get the first letter to send to the translation map
  acc.map! { |x| x[0] }
end

alpha_pat = /\A([A-Z]{1,3})\d.*\Z/
to_field 'lc_alpha_facet_sim', extract_marc('050a', first: true) do |_rec, acc|
  acc.map! do |x|
    (m = alpha_pat.match(x)) ? m[1] : nil
  end
  acc.compact! # eliminate nils
end

to_field 'lc_b4cutter_facet_sim', extract_marc('050a', first: true)

# Material Characteristics

## 300 / 340 Physical description / physical medium
to_field 'phys_desc_ssm', extract_marc('300abcefg3:340abcdefhijkmno3', trim_punctuation: true)

## 380 Form of work
to_field 'form_work_ssm', extract_marc('380a', trim_punctuation: true)

## Work other characteristics

## 310 / 321 Current publication frequency / former publication frequency
to_field 'frequency_ssm', extract_marc('310ab:321ab')

## 385 Audience
to_field 'audience_ssm', extract_marc('385ma3')

## A/v and print music works

## 306 Duration
to_field 'duration_ssm', extract_marc('306a')

## 344 Sound characteristics
to_field 'sound_ssm', extract_marc('344abcdefgh3')

## 383 Numeric designation of musical work
to_field 'music_numerical_ssm', extract_marc('383abcde')

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
notfulltext = /abstract|description|sample text|table of contents|/i

to_field('url_fulltext_display_ssm') do |rec, acc|
  rec.fields('856').each do |f|
    case f.indicator2
    when '0'
      f.find_all { |sf| sf.code == 'u' }.each do |url|
        acc << url.value
      end
    when '2'
      # do nothing
    else
      z3 = [f['z'], f['3']].join(' ')
      unless notfulltext.match(z3)
        acc << f['u'] unless f['u'].nil?
      end
    end
  end
end

# Very similar to url_fulltext_display_ssm. Should DRY up.
to_field 'url_suppl_display_ssm' do |rec, acc|
  rec.fields('856').each do |f|
    case f.indicator2
    when '2'
      f.find_all { |sf| sf.code == 'u' }.each do |url|
        acc << url.value
      end
    when '0'
      # do nothing
    else
      z3 = [f['z'], f['3']].join(' ')
      if notfulltext.match(z3)
        acc << f['u'] unless f['u'].nil?
      end
    end
  end
end

## Notes fields
# Bound with notes
to_field 'bound_with_notes_ssm' do |record, accumulator|
  next unless record['591']

  bound_with_notes = record.fields('591')
  bound_with_notes.each do |subfield|
    next if subfield.codes.include? 'c'

    accumulator << subfield.value
  end
end

# Make a linked title to the bound parent
to_field 'bound_with_title_struct' do |record, accumulator|
  next unless record['591']

  bound_with_title = record.fields('591')
  bound_with_title.each do |subfield|
    next unless subfield.codes.include? 'c'

    # Implied that a is available when c is present
    bound_title = subfield.subfields.select { |sub| sub.code == 'a' }.collect(&:value)
    bound_catkey = subfield.subfields.select { |sub| sub.code == 'c' }.collect(&:value)
    accumulator << "{\"catkey\": #{bound_catkey.first.to_json}, \"linktext\": #{bound_title.first.to_json}}"
  end
end
