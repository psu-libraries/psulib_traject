# frozen_string_literal: true

RSpec.describe PsulibTraject::Macros::Subjects do
  let(:result) { indexer.map_record(record) }

  describe 'process_subject_hierarchy' do
    let(:record) { MarcBot.build(:subject_facet) }

    it 'only separates v,x,y,z with em dash, strips punctuation' do
      expect(result['subject_display_ssm']).to include(
        'Include',
        "John. Title#{described_class::SEPARATOR}split genre 2015",
        "Fiction#{described_class::SEPARATOR}1492#{described_class::SEPARATOR}don't ignore TITLE"
      )
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

    context "when 'pst' is not in subfield 2" do
      let(:record) { MarcBot.build(:non_pst_subjects) }

      it { is_expected.to contain_exactly(['A', 'B', 'C'].join(described_class::SEPARATOR)) }
    end

    context "when 'pst' is in subfield 2" do
      let(:record) { MarcBot.build(:pst_subjects) }

      it { is_expected.to contain_exactly(
        ['A', 'B', 'C'].join(described_class::SEPARATOR),
        ['L', 'M', 'N'].join(described_class::SEPARATOR)
      )}
    end
  end
end
