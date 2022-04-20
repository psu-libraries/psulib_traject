# frozen_string_literal: true

RSpec.describe PsulibTraject::Processors::OclcExtract do
  let(:oclc_extract) { described_class.new(record, accumulator) }

  describe '#extract_deprecated_oclcs' do
    let(:record) do
      object_double('Marc Record',
                    fields: [
                      object_double('Marc Field', {
                                      tag: '035', subfields: [
                                        object_double('Marc Subfield', {
                                                        code: 'z',
                                                        value: '(OCoLC)12345678'
                                                      })
                                      ]
                                    }),
                      object_double('Marc Field', {
                                      tag: '019', subfields: [
                                        object_double('Marc Subfield', {
                                                        code: 'a',
                                                        value: '87654321'
                                                      }),
                                        object_double('Marc Subfield', {
                                                        code: 'a',
                                                        value: '8765432121351235123515'
                                                      }),
                                        object_double('Marc Subfield', {
                                                        code: 'a',
                                                        value: 'MARS'
                                                      })
                                      ]
                                    })
                    ])
    end
    let(:accumulator) { [] }

    it 'extracts deprecated oclcs' do
      oclc_extract.extract_deprecated_oclcs
      expect(accumulator).to eq ['12345678', '87654321']
    end
  end

  describe '#extract_primary_oclcs' do
    let(:record) do
      object_double('Marc Record',
                    fields: [
                      object_double('Marc Field', {
                                      tag: '035', subfields: [
                                        object_double('Marc Subfield', {
                                                        code: 'a',
                                                        value: '(OCoLC)56789123'
                                                      }),
                                        object_double('Marc Subfield', {
                                                        code: 'z',
                                                        value: '(OCoLC)12345678'
                                                      })
                                      ]
                                    })
                    ])
    end
    let(:accumulator) { [] }

    it 'extracts primary oclc' do
      oclc_extract.extract_primary_oclc
      expect(accumulator).to eq ['56789123']
    end
  end
end
