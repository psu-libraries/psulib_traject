# frozen_string_literal: true

RSpec.describe PsulibTraject::Macros::Subjects do
  let(:result) { indexer.map_record(record) }
  let(:separator) { PsulibTraject::SubjectHeading::SEPARATOR }

  describe 'process_subject_hierarchy' do
    let(:record) { MarcBot.build(:subject_facet) }

    it 'only separates v,x,y,z with em dash, strips punctuation' do
      expect(result['subject_display_ssm']).to include(
        'Include',
        "John. Title#{separator}split genre 2015",
        "Fiction#{separator}1492#{separator}don't ignore TITLE"
      )
    end

    context 'when empty 650 only' do
      let(:record) { MarcBot.build(:subject_empty_650) }

      it 'handles empty 650s correctly' do
        expect(result['subject_display_ssm']).to be_nil
      end
    end
  end

  describe 'process_subject_topic_facet' do
    let(:record) { MarcBot.build(:subject_topic_facet) }

    it 'includes subjects split along v, x, y and z, strips punctuation' do
      expect(result['subject_topic_facet']).to include('John. Title 2015', 'Fiction')
    end
  end

  describe '#process_subject_browse_facet' do
    subject { result['subject_browse_facet'] }

    context "when 'pst' is not in subfield 2 for 650 subjects" do
      let(:record) { MarcBot.build(:non_pst_subjects_650) }

      it { is_expected.to contain_exactly(['A', 'B', 'C'].join(separator)) }
    end

    context 'when max length rule should be applied' do
      let(:record) { MarcBot.build(:non_pst_subjects_non_650) }

      it { is_expected.to contain_exactly('A B C D', 'E F G H', 'L M N O', 'P R S T',
                                          ['1 2', '3', '4', '5', '6'].join(separator),
                                          ['7', '8', '9', '10', '11'].join(separator),
                                          ['12', '13', '14', '15', '16'].join(separator)) }
    end

    context "when 'pst' is in subfield 2" do
      let(:record) { MarcBot.build(:pst_subjects) }

      it { is_expected.to contain_exactly(
        ['A', 'B', 'C'].join(separator),
        ['L', 'M', 'N'].join(separator)
      )}
    end

    context 'when empty 650 only' do
      let(:record) { MarcBot.build(:subject_empty_650) }

      it 'handles empty 650s correctly' do
        expect(result['subject_browse_facet']).to be_nil
      end
    end

    context 'when subject headings are repeated' do
      let(:record) { MarcBot.build(:repeated_headings) }

      it { is_expected.to contain_exactly(
        ['Quilting', 'Pennsylvania', 'Cumberland County', 'History', '18th century'].join(separator),
        ['Quilting', 'Pennsylvania', 'Cumberland County', 'History', '19th century'].join(separator)
      )}
    end
  end
end
