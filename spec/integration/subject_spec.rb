# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Subjects' do
  let(:result) { indexed_record('subject_browse.mrc') }

  it 'creates facets for subject browsing' do
    expect(result['subject_browse_facet']).to contain_exactly(
      'Quilting—Pennsylvania—Cumberland County—History—19th century',
      'Quiltmakers—Pennsylvania—Cumberland County—History—18th century',
      'Quilting—Pennsylvania—Cumberland County—History—18th century',
      'Quiltmakers—Pennsylvania—Cumberland County—History—19th century'
    )
  end
end
