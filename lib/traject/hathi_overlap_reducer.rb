# frozen_string_literal: true

# Reduces the HathiTrust overlap report down to something usable.
class HathiOverlapReducer
  EXCLUDE_FROM_HATHI = ['2168941'].freeze
  MAX_POSSIBLE_DUPES = 8

  def initialize(file)
    hathi_csv = CSV.read(file, headers: true, col_sep: "\t")
    hathi_csv.delete('oclc')
    hathi_csv.delete('rights')
    @hathi_report_filtered = hathi_csv.reject { |overlap_record| overlap_record['access'].nil? }
                                      .reject { |overlap_record| EXCLUDE_FROM_HATHI.include?(overlap_record['local_id']) }
  end

  def hashify
    dupes = find_dupes

    # Truely unique, as opposed to `uniq` which would just lop off dupes. These true uniques don't need any further
    # mapping or reducing (and are the vast majority of rows in the dataset).
    true_uniqs = @hathi_report_filtered - dupes
    reduced_dupes = dupe_reduction dupes
    # Transform to Hash indexed by local_id
    (true_uniqs + reduced_dupes).group_by { |row| row['local_id'] }
  end

  private

  # Gathers *all* rows that are duplicates
  def find_dupes
    @hathi_report_filtered.find_all.with_index do |row, index|
      row if (row['local_id'] == @hathi_report_filtered.at(index + 1)&.[]('local_id')) || (row['local_id'] == @hathi_report_filtered.at(index - 1)['local_id'])
    end.compact
  end

  def dupe_reduction(dupes)
    dupes.map.with_index do |record, index|
      next if record['local_id'] == dupes.at(index - 1)['local_id']

      dupe_rows = dupes[index...index + MAX_POSSIBLE_DUPES].find_all { |r| r['local_id'] == record['local_id'] }
      reduce_dupe_rows dupe_rows
    end.compact
  end

  def reduce_dupe_rows(rows)
    rows.reduce do |memo, rec|
      next memo unless memo['access'] != rec['access']

      { 'local_id' => memo['local_id'],
        'access' => both_multi?(memo, rec) ? 'deny' : 'allow' }
    end
  end

  def both_multi?(memo, rec)
    (memo['item_type'] == 'multi' || memo['item_type'] == 'serial') && (rec['item_type'] == 'multi' || rec['item_type'] == 'serial')
  end
end
