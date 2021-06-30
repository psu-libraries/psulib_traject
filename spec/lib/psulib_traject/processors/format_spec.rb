# frozen_string_literal: true

RSpec.describe PsulibTraject::Processors::Format do
  subject { result['format'] }

  let(:result) { indexer.map_record(MARC::Reader.new(File.join('./spec/fixtures', record)).to_a.first) }

  describe '#resolve_formats' do
    context 'with an empty record' do
      let(:record) { MarcBot.build(:record) }
      let(:result) { indexer.map_record(record) }

      it { is_expected.to contain_exactly('Other') }
    end

    context 'with the record as no 008' do
      let(:record) { 'format_no_008.mrc' }

      it { is_expected.to contain_exactly('Microfilm/Microfiche', 'Book') }
    end

    context 'with multiple 949s' do
      let(:record) { 'format_949t_juvenile_book.mrc' }

      it { is_expected.to contain_exactly 'Instructional Material', 'Juvenile Book', 'Microfilm/Microfiche' }
    end

    context 'with both Statute and Microfilm/Microfiche in 949t' do
      let(:record) { 'format_949t_statute.mrc' }

      it { is_expected.to contain_exactly 'Statute', 'Microfilm/Microfiche' }
    end

    context 'with Microfilm/Microfiche from 006' do
      let(:record) { 'format_006_instructional_material.mrc' }

      it { is_expected.to contain_exactly 'Microfilm/Microfiche', 'Thesis/Dissertation' }
    end

    context 'with Microfilm/Microfiche in government docs' do
      let(:record) { 'format_gov_doc.mrc' }

      it { is_expected.to contain_exactly 'Microfilm/Microfiche' }
    end

    context 'with Microfilm/Microfiche in periodicals' do
      let(:record) { '483004.mrc' }

      it { is_expected.to contain_exactly 'Microfilm/Microfiche', 'Journal/Periodical' }
    end

    context 'with Instructional Material in the 006 field' do
      let(:record) { MarcBot.build(:record, f006: "#{'x' * 16}q") }
      let(:result) { indexer.map_record(record) }

      it { is_expected.to contain_exactly 'Instructional Material' }
    end

    context 'with Instructional Material in the 008 field' do
      let(:record) { MarcBot.build(:record, f008: "#{'x' * 33}q") }
      let(:result) { indexer.map_record(record) }

      it { is_expected.to contain_exactly 'Instructional Material' }
    end

    context 'with 260b or 264b contain variations of "University Press"' do
      let(:record) { 'format_university_press.mrc' }

      it { is_expected.to contain_exactly 'Book' }
    end

    context 'with Article in leader byte 6 and byte 7' do
      let(:record) { 'format_article.mrc' }

      it { is_expected.to contain_exactly 'Article' }
    end

    context 'when overriding Book in leader byte 6 and byte 7' do
      let(:record) { 'format_leader6_book_override.mrc' }

      it { is_expected.to contain_exactly 'Book' }
    end

    context 'with Thesis/Dissertation if the record has a 502' do
      let(:record) { 'format_502_thesis.mrc' }

      it { is_expected.to contain_exactly 'Thesis/Dissertation' }
    end

    context 'with Newspaper' do
      let(:record) { 'format_newspaper.mrc' }

      it { is_expected.to contain_exactly 'Newspaper' }
    end

    context 'with Games/Toys from 006' do
      let(:record) { 'format_006_games.mrc' }

      it { is_expected.to contain_exactly 'Games/Toys' }
    end

    context 'with Games/Toys from 008' do
      let(:record) { 'format_games.mrc' }

      it { is_expected.to contain_exactly 'Games/Toys' }
    end

    context 'with Proceeding/Congress' do
      let(:record) { 'format_proceeding.mrc' }

      it { is_expected.to contain_exactly 'Proceeding/Congress' }
    end

    context 'with Proceeding/Congress from $6xx' do
      let(:record) { 'format_congress.mrc' }

      it { is_expected.to contain_exactly 'Proceeding/Congress' }
    end

    context 'with Other when no other format found' do
      let(:record) do
        MarcBot.build(:record, leader: '00085cxm a2200049Ii 4500', f008: '150224t21052015cau dq x eng d')
      end
      let(:result) { indexer.map_record(record) }

      it { is_expected.to contain_exactly 'Other' }
    end
  end
end
