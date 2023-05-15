# frozen_string_literal: true

RSpec.describe PsulibTraject::Macros::SeriesTitle do
  let(:result) { indexer.map_record(record) }

  describe 'series_title_display' do
    context 'when only an 830 field is present' do
      let(:record) { MarcBot.build(:series_title_830_only) }

      it 'stores the 830 data in the series_title_display_ssm' do
        expect(result['series_title_display_ssm']).to eq(
          ['Series Title With 830 4']
        )
      end
    end

    context 'when an 830 field and 490 field are present but 490 does not get appended' do
      let(:record) { MarcBot.build(:series_title_830_and_490_no_append_409) }

      it 'stores the 830 data in the series_title_display_ssm' do
        expect(result['series_title_display_ssm']).to eq(
          ['Series Title With 830 4']
        )
      end
    end

    context 'when an 830 field and 490 field are present' do
      let(:record) { MarcBot.build(:series_title_830_and_490) }

      it 'stores the 830 and 490 data in the series_title_display_ssm' do
        expect(result['series_title_display_ssm']).to eq(
          ['Series Title With 830 4', 'Series Title With 490 4']
        )
      end
    end

    context 'when an 830 field and 440 field are present' do
      let(:record) { MarcBot.build(:series_title_830_and_440) }

      it 'stores the 440 data in the series_title_display_ssm' do
        expect(result['series_title_display_ssm']).to eq(
          ['Series Title With 440 1']
        )
      end
    end

    context 'when only a 490 field is present' do
      let(:record) { MarcBot.build(:series_title_490_only) }

      it 'stores the 490 data in the series_title_display_ssm' do
        expect(result['series_title_display_ssm']).to eq(
          ['Series Title With 490 4']
        )
      end
    end

    context 'when a 490 field and 440 field are present' do
      let(:record) { MarcBot.build(:series_title_490_and_440) }

      it 'stores the 440 data in the series_title_display_ssm' do
        expect(result['series_title_display_ssm']).to eq(
          ['Series Title With 440 1']
        )
      end
    end

    context 'when only a 440 field is present' do
      let(:record) { MarcBot.build(:series_title_440_only) }

      it 'stores the 440 data in the series_title_display_ssm' do
        expect(result['series_title_display_ssm']).to eq(
          ['Series Title With 440 1']
        )
      end
    end
  end
end
