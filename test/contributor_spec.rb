require_relative '../lib/epuber/book/vendor/contributor'


module Epuber
	describe Contributor do

		before do
			@contributor = Contributor.new('Jason Fried', 'FRIED, Jason', 'aut')
		end

		it 'should return same values' do
			expect(@contributor.pretty_name).to eq 'Jason Fried'
			expect(@contributor.file_as).to eq 'FRIED, Jason'
			expect(@contributor.role).to eq 'aut'
		end
	end

	describe NormalContributor do

		before do
			@contributor = NormalContributor.new('Jason', 'Fried', 'aut')
		end

		it 'formats file_as' do
			expect(@contributor.file_as).to eq 'FRIED, Jason'
		end

		it 'formats pretty_name' do
			expect(@contributor.pretty_name).to eq 'Jason Fried'
		end
	end

	describe 'Contributor.create' do

		it 'parse Contributor from Hash with symbols :first_name and :last_name' do
			hash = {
				:first_name => 'Jason',
				:last_name  => 'Fried'
			}

			contributor = Contributor.create(hash, 'aut')

			expect(contributor).to be_a(NormalContributor)
			expect(contributor.first_name).to eq 'Jason'
			expect(contributor.last_name).to eq 'Fried'
			expect(contributor.role).to eq 'aut'
		end
	end
end
