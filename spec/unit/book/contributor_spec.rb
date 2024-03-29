# frozen_string_literal: true

require_relative '../../spec_helper'


module Epuber
  class Book
    describe Contributor do
      before do
        @contributor = described_class.new('Jason Fried', 'FRIED, Jason', 'aut')
      end

      it 'returns same values' do
        expect(@contributor.pretty_name).to eq 'Jason Fried'
        expect(@contributor.file_as).to eq 'FRIED, Jason'
        expect(@contributor.role).to eq 'aut'
      end
    end

    describe NormalContributor do
      before do
        @contributor = described_class.new('Jason', 'Fried', 'aut')
      end

      it 'formats file_as' do
        expect(@contributor.file_as).to eq 'FRIED, Jason'
      end

      it 'formats pretty_name' do
        expect(@contributor.pretty_name).to eq 'Jason Fried'
      end

      it 'pretty_name is readonly' do
        expect do
          @contributor.pretty_name = ''
        end.to raise_error NameError
      end

      it 'file_as is readonly' do
        expect do
          @contributor.file_as = ''
        end.to raise_error NameError
      end
    end

    describe 'Epuber::Contributor.from_obj' do
      it 'parse Contributor from Hash with symbols :file_as and :pretty_name' do
        hash = {
          pretty_name: 'Jason Fried',
          file_as: 'FRIED, Jason',
        }

        contributor = Contributor.from_obj(hash, 'aut')

        expect(contributor).to be_a(Contributor)
        expect(contributor.pretty_name).to eq 'Jason Fried'
        expect(contributor.file_as).to eq 'FRIED, Jason'
      end

      it 'parse Contributor from Hash with symbols :file_as, :pretty_name and :role' do
        hash = {
          pretty_name: 'Jason Fried',
          file_as: 'FRIED, Jason',
          role: 'aut2',
        }

        contributor = Contributor.from_obj(hash)

        expect(contributor).to be_a(Contributor)
        expect(contributor.pretty_name).to eq 'Jason Fried'
        expect(contributor.file_as).to eq 'FRIED, Jason'
        expect(contributor.role).to eq 'aut2'
      end

      it 'parse Contributor from Hash with symbols :first_name and :last_name' do
        hash = {
          first_name: 'Jason',
          last_name: 'Fried',
        }

        contributor = Contributor.from_obj(hash, 'aut')

        expect(contributor).to be_a(NormalContributor)
        expect(contributor.first_name).to eq 'Jason'
        expect(contributor.last_name).to eq 'Fried'
        expect(contributor.role).to eq 'aut'
      end

      it 'parse Contributor from Hash with symbols :first_name, :last_name and :role' do
        hash = {
          first_name: 'Jason',
          last_name: 'Fried',
          role: 'aut3',
        }

        contributor = Contributor.from_obj(hash)

        expect(contributor).to be_a(NormalContributor)
        expect(contributor.first_name).to eq 'Jason'
        expect(contributor.last_name).to eq 'Fried'
        expect(contributor.role).to eq 'aut3'
      end

      it 'parse Contributor from Hash with symbol :name' do
        hash = {
          name: 'Jason Fried',
        }

        contributor = Contributor.from_obj(hash, 'aut')

        expect(contributor).to be_a(NormalContributor)
        expect(contributor.first_name).to eq 'Jason'
        expect(contributor.last_name).to eq 'Fried'
        expect(contributor.role).to eq 'aut'
      end

      it 'parse Contributor from Hash with symbol :name and :role' do
        hash = {
          name: 'Jason Fried',
          role: 'aut4',
        }

        contributor = Contributor.from_obj(hash)

        expect(contributor).to be_a(NormalContributor)
        expect(contributor.first_name).to eq 'Jason'
        expect(contributor.last_name).to eq 'Fried'
        expect(contributor.role).to eq 'aut4'
      end

      it 'parse Contributor from simple name in string' do
        contributor = Contributor.from_obj('Jason Fried', 'aut')

        expect(contributor).to be_a(NormalContributor)
        expect(contributor.first_name).to eq 'Jason'
        expect(contributor.last_name).to eq 'Fried'
      end

      it 'parse Contributor from simple name with middle name in string' do
        contributor = Contributor.from_obj('David Heinemeier Hansson', 'aut')

        expect(contributor).to be_a(NormalContributor)
        expect(contributor.first_name).to eq 'David Heinemeier'
        expect(contributor.last_name).to eq 'Hansson'
      end
    end
  end
end
