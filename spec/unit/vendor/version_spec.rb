# frozen_string_literal: true

module Epuber
  describe Version do
    describe 'direct comparison' do
      it 'compares equal values' do
        one = described_class.new('1.0.0')

        expect(one <=> one).to eq(0) # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
        expect(one <=> described_class.new('1.0.0')).to eq(0)
      end

      it 'compares diff values' do
        expect(described_class.new('1.0.0') <=> described_class.new('1.0.1')).to eq(-1)

        expect(described_class.new('1.0.0') < described_class.new('1.0.1')).to be_truthy
      end
    end

    describe 'indirect comparison' do
      it 'compares versions' do
        expect(described_class.new('1.0.0') < '1.0.1').to be_truthy
        expect(described_class.new('1.0.0') > '1.0.1').to be_falsey

        expect(described_class.new('3.0') >= 3.0).to be_truthy
      end
    end
  end
end
