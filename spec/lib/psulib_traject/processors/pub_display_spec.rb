# frozen_string_literal: true

RSpec.describe PsulibTraject::Processors::PubDisplay do
  let(:context) { instance_double 'Context' }

  before do
    allow(context).to receive(:output_hash).and_return(output_hash)
  end

  describe '::call' do
    context 'when there is not a vernacular version of the field' do
      let(:output_hash) do
        { 'edition_vern' => nil,
          'edition_display_ssm' => nil,
          'edition_latin' => ['thing'] }
      end

      it 'sets the field_display_ssm to the field_latin and deletes field_latin' do
        described_class.new('edition', context).call
        expect(output_hash['edition_display_ssm']).to eq ['thing']
        expect(output_hash['edition_latin']).to eq nil
      end
    end

    context 'when there is a vernacular version of the field' do
      context 'when field_vern contains right to left arabic equals sign' do
        context 'when there is a period on the right end of field_vern' do
          let(:output_hash) do
            { 'edition_vern' => ['چاپ اول.'],
              'edition_display_ssm' => nil,
              'edition_latin' => ['Chāp-i avval.'] }
          end

          it 'moves the period of the vern to the left, adds field_latin & field_vern to field_display_ssm, and deletes field_latin and field_vern' do
            described_class.new('edition', context).call
            expect(output_hash['edition_display_ssm']).to eq ['Chāp-i avval.', '.چاپ اول']
            expect(output_hash['edition_latin']).to eq nil
            expect(output_hash['edition_vern']).to eq nil
          end
        end

        context 'when there is not a period on the right end of field_vern' do
          let(:output_hash) do
            { 'edition_vern' => ['چاپ اول'],
              'edition_display_ssm' => nil,
              'edition_latin' => ['Chāp-i avval.'] }
          end

          it 'does not change the field_vern, adds field_latin & field_vern to field_display_ssm, and deletes field_latin and field_vern' do
            described_class.new('edition', context).call
            expect(output_hash['edition_display_ssm']).to eq ['Chāp-i avval.', 'چاپ اول']
            expect(output_hash['edition_latin']).to eq nil
            expect(output_hash['edition_vern']).to eq nil
          end
        end
      end

      context 'when field_vern does not contain right to left arabic equals sign' do
        let(:output_hash) do
          { 'edition_vern' => ['東京 : 早川書房, 1999.'],
            'edition_display_ssm' => nil,
            'edition_latin' => ['Tōkyō : Hayakawa Shobō, 1999.'] }
        end

        it 'adds field_latin & field_vern to field_display_ssm and deletes field_latin and field_vern' do
          described_class.new('edition', context).call
          expect(output_hash['edition_display_ssm']).to eq ['Tōkyō : Hayakawa Shobō, 1999.', '東京 : 早川書房, 1999.']
          expect(output_hash['edition_latin']).to eq nil
          expect(output_hash['edition_vern']).to eq nil
        end
      end
    end
  end
end
