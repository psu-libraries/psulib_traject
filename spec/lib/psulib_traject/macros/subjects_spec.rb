# frozen_string_literal: true

RSpec.describe PsulibTraject::Macros::Subjects do
  let(:result) { indexer.map_record(record) }

  describe 'process_subject_hierarchy' do
    let(:record) do
      MarcBot.build(
        :record,
        f610: {
          indicator2: '5',
          a: 'Include'
        },
        f600: {
          indicator2: '0',
          a: 'John.',
          t: 'Title.',
          v: 'split genre',
          d: '2015',
          2 => 'special'
        },
        f630: {
          indicator2: '0',
          x: 'Fiction',
          y: '1492',
          z: "don't ignore",
          t: 'TITLE.'
        }
      )
    end

    it 'only separates v,x,y,z with em dash, strips punctuation' do
      expect(result['subject_display_ssm']).to include(
        'Include',
        "John. Title#{described_class::SEPARATOR}split genre 2015",
        "Fiction#{described_class::SEPARATOR}1492#{described_class::SEPARATOR}don't ignore TITLE"
      )
    end
  end

  describe 'process_subject_topic_facet' do
    let(:record) do
      MarcBot.build(
        :record,
        f600: {
          indicator2: '0',
          a: 'John.',
          x: 'Join',
          t: 'Title',
          d: '2015.'
        },
        f650: {
          indicator2: '0',
          x: 'Fiction',
          y: '1492',
          v: 'split genre'
        }
      )
    end

    it 'includes subjects split along v, x, y and z, strips punctuation' do
      expect(result['subject_topic_facet']).to include('John. Title 2015', 'Fiction')
    end
  end
end
