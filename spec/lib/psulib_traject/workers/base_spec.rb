# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PsulibTraject::Workers::Base do
  before do
    class TestWorker < PsulibTraject::Workers::Base
      def perform(_arg1, _arg2, options: [])
        true
      end
    end
  end

  describe '::perform_now' do
    context 'without options' do
      it { expect(TestWorker.perform_now('arg1', 'arg2')).to be(true) }
    end

    context 'with options' do
      it { expect(TestWorker.perform_now('arg1', 'arg2', options: ['a', 'b'])).to be(true) }
    end
  end
end
