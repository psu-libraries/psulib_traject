# frozen_string_literal: true

RSpec.describe PsulibTraject::NullObject do
  it { is_expected.to be_nil }
  its(:respond_to_missing?) { is_expected.to be_nil }
  its(:method_missing) { is_expected.to be_nil }
end
