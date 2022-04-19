# frozen_string_literal: true

RSpec.describe PsulibTraject::Macros do
  before do
    extend described_class
  end

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

    it 'extracts deprecated oclcs' do
      accumulator = []
      extract_deprecated_oclcs.call(record, accumulator)
      expect(accumulator).to eq ['12345678', '87654321']
    end
  end
end
