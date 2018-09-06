#
# PSU Library MARC to Solr indexing
# Uses traject: https://github.com/traject-project/traject
#

#Check if we are using jruby and store.
is_jruby = RUBY_ENGINE == 'jruby'
if is_jruby
  require 'traject/marc4j_reader'
end

# Translation maps
# './lib/translation_maps/'
$:.unshift  "#{File.dirname(__FILE__)}/lib"

require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

# To have access to the traject marc format/carrier classifier
require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

require 'library_stdnums'

ATOZ = ('a'..'z').to_a.join('')
ATOU = ('a'..'u').to_a.join('')

settings do
  # Where to find solr server to write to
  provide "solr.url", "http://localhost:8983/solr/blacklight-core"
  provide "log.batch_size", 10_000
  # set this to be non-negative if threshold should be enforced
  # provide 'solr_writer.max_skipped', -1

  # solr.version doesn't currently do anything, but set it
  # anyway, in the future it will warn you if you have settings
  # that may not work with your version.
  provide "solr.version", "7.4.0"

  if is_jruby
    provide "reader_class_name", "Traject::Marc4JReader"
    provide "marc4j_reader.permissive", true
    provide "marc4j_reader.source_encoding", "UTF-8"
    # defaults to 1 less than the number of processors detected on your machine
    # provide 'processing_thread_pool', 2
    provide "solrj_writer.commit_on_close", "true"
  end
end

logger.info RUBY_DESCRIPTION

to_field "id", extract_marc("001", :first => true)

to_field "marc_display", serialized_marc(:format => "xml", :allow_oversized => true)

to_field "text", extract_all_marc_values do |r, acc|
  acc.replace [acc.join(' ')] # turn it into a single string
end

to_field "language_facet", marc_languages("008[35-37]:041a:041d:")

#    to_field "format", get_format
to_field "format", marc_formats

to_field "isbn_t",  extract_marc('020a', :separator=>nil) do |rec, acc|
  orig = acc.dup
  acc.map!{|x| StdNum::ISBN.allNormalizedValues(x)}
  acc << orig
  acc.flatten!
  acc.uniq!
end

to_field 'material_type_display', extract_marc('300a', :trim_punctuation => true)

# Title fields

# Extract only the title a, then the title/subtitle for title searching, exact matches, weighting.
to_field 'title_t', extract_marc('245a')
to_field 'title_245ab_t', extract_marc('245ab')

# display forms of the title
to_field 'title_display', extract_marc('245abcfgknps', :alternate_script=>false, :trim_punctuation => true)
to_field 'title_vern_display', extract_marc('245abcfgknps', :alternate_script=>true, :trim_punctuation => true)

to_field 'uniform_title_display', extract_marc('130adfklmnoprs:240adfklmnoprs:730ai', :alternate_script=>false, :trim_punctuation => true)
to_field 'uniform_title_vern_display', extract_marc('130adfklmnoprs:240adfklmnoprs:730ai', :alternate_script=>true, :trim_punctuation => true)

to_field 'additional_title_display', extract_marc('210ab:246iabfgnp:247abcdefgnp', :alternate_script=>false)
to_field 'additional_title_vern_display', extract_marc('210ab:246iabfgnp:247abcdefgnp', :alternate_script=>true)

to_field 'related_title_display', extract_marc('700ilktmnoprs3:710ilktmnoprs3:711ilktmnoprs3:730adfgiklmnoprst3:740anp', :alternate_script=>false, :trim_punctuation => true)
to_field 'related_title_vern_display', extract_marc('700ilktmnoprs3:710ilktmnoprs3:711ilktmnoprs3:730adfgiklmnoprst3:740anp', :alternate_script=>true, :trim_punctuation => true)

#    additional title fields
to_field 'title_addl_t', extract_marc(%W{
  245abnps
  130#{ATOZ}
  240abcdefgklmnopqrs
  210ab
  222ab
  242abnp
  243abcdefgklmnopqrs
  246abcdefgnp
  247abcdefgnp
}.join(':'))

to_field 'title_added_entry_t', extract_marc(%W{
  700gklmnoprst
  710fgklmnopqrst
  711fgklnpst
  730abcdefgklmnopqrst
  740anp
}.join(':'))

to_field 'title_related_t', extract_marc(%W{
  505t
  700lktmnoprs
  710lktmnoprs
  711lktmnoprs
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
}.join(':'), :trim_punctuation => true)

# Could we slice ` --` off this in cases from 505? Trim punctuation doesn't handle it

to_field 'title_sort', marc_sortable_title

# Author fields

to_field 'author_t', extract_marc("100abcegqu:110abcdegnu:111acdegjnqu")
to_field 'author_addl_t', extract_marc("700abcegqu:710abcdegnu:711acdegjnqu")
to_field 'author_display', extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}", :alternate_script=>false)
to_field 'author_vern_display', extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}", :alternate_script=>:only)

# JSTOR isn't an author. Try to not use it as one
to_field 'author_sort', marc_sortable_author

# Subject fields
to_field 'subject_t', extract_marc(%W(
  600#{ATOU}
  610#{ATOU}
  611#{ATOU}
  630#{ATOU}
  650abcde
  651ae
  653a:654abcde:655abc
).join(':'))
to_field 'subject_addl_t', extract_marc("600vwxyz:610vwxyz:611vwxyz:630vwxyz:650vwxyz:651vwxyz:654vwxyz:655vwxyz")
to_field 'subject_topic_facet', extract_marc("600abcdq:610ab:611ab:630aa:650aa:653aa:654ab:655ab", :trim_punctuation => true)
to_field 'subject_era_facet',  extract_marc("650y:651y:654y:655y", :trim_punctuation => true)
to_field 'subject_geo_facet',  extract_marc("651a:650z",:trim_punctuation => true )

# Publication fields
to_field 'published_display', extract_marc('260a', :trim_punctuation => true, :alternate_script=>false)
to_field 'published_vern_display', extract_marc('260a', :trim_punctuation => true, :alternate_script=>:only)
to_field 'pub_date', marc_publication_date

# Series fields

to_field 'series_title_t', extract_marc("440anpv:490av")
to_field 'series_title_display', extract_marc('490avlx3:440anpvx', :alternate_script=>false, :trim_punctuation => true)

# Call Number fields
to_field 'lc_callnum_display', extract_marc('050ab', :first => true)
to_field 'lc_1letter_facet', extract_marc('050ab', :first=>true, :translation_map=>'callnumber_map') do |rec, acc|
# Just get the first letter to send to the translation map
  acc.map!{|x| x[0]}
end

alpha_pat = /\A([A-Z]{1,3})\d.*\Z/
to_field 'lc_alpha_facet', extract_marc('050a', :first=>true) do |rec, acc|
  acc.map! do |x|
    (m = alpha_pat.match(x)) ? m[1] : nil
  end
  acc.compact! # eliminate nils
end

to_field 'lc_b4cutter_facet', extract_marc('050a', :first=>true)

# URL Fields

notfulltext = /abstract|description|sample text|table of contents|/i

to_field('url_fulltext_display') do |rec, acc|
  rec.fields('856').each do |f|
    case f.indicator2
    when '0'
      f.find_all{|sf| sf.code == 'u'}.each do |url|
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

# Very similar to url_fulltext_display. Should DRY up.
to_field 'url_suppl_display' do |rec, acc|
  rec.fields('856').each do |f|
    case f.indicator2
    when '2'
      f.find_all{|sf| sf.code == 'u'}.each do |url|
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
