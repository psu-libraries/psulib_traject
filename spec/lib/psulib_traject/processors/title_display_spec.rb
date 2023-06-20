# frozen_string_literal: true

RSpec.describe PsulibTraject::Processors::TitleDisplay do
  let(:context) { instance_double 'Context' }

  before do
    allow(context).to receive(:output_hash).and_return(output_hash)
  end

  describe '::call' do
    context 'when title_vern is nil' do
      let(:output_hash) do
        { 'title_vern' => nil,
          'title_display_ssm' => nil,
          'title_latin_display_ssm' => ['thing'] }
      end

      it 'sets the title_display_ssm to the title_latin_display_ssm and deletes title_latin_display_ssm' do
        described_class.new(context).call
        expect(output_hash['title_display_ssm']).to eq ['thing']
        expect(output_hash['title_latin_display_ssm']).to be_nil
      end
    end

    context 'when title_vern is not nil' do
      context 'when title_vern contains right to left arabic equals sign' do
        let(:output_hash) do
          { 'title_vern' => ['جولة في عالم الفن الإسلامي‏' + ' =‏ ‏'],
            'title_display_ssm' => nil,
            'title_latin_display_ssm' => nil }
        end

        it 'sets the title_display_ssm to the title_vern, replaces right to left equals sign, and deletes title_vern' do
          described_class.new(context).call
          expect(output_hash['title_display_ssm']).to eq ['جولة في عالم الفن الإسلامي‏' + ' = ']
          expect(output_hash['title_vern']).to be_nil
        end
      end

      context 'when title_vern does not contain right to left arabic equals sign' do
        let(:output_hash) do
          { 'title_vern' => ['thing'],
            'title_display_ssm' => nil,
            'title_latin_display_ssm' => nil }
        end

        it 'sets the title_display_ssm to the title_vern and deletes title_vern' do
          described_class.new(context).call
          expect(output_hash['title_display_ssm']).to eq ['thing']
          expect(output_hash['title_vern']).to be_nil
        end
      end
    end
  end
end
