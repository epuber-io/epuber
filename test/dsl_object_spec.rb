require 'rspec'

require_relative '../lib/epuber/dsl/dsl_object'


module Epuber

	describe DSLObject do

		context 'simple attributes' do
			class TestClass < DSLObject
				attribute :optional_string
				attribute :optional_number,
				          types: [ Fixnum ]
			end

			before do
				@example = TestClass.new
			end

			it 'initial value is nil' do
				expect(@example.optional_string).to be nil
				expect(@example.optional_number).to be nil
			end

			it 'stores value' do
				@example.optional_string = 'aaa'
				expect(@example.optional_string).to eq 'aaa'

				@example.optional_number = 1
				expect(@example.optional_number).to eq 1
			end

			it 'optional value should validate without problem' do
				expect {
					@example.validate
				}.to_not raise_error
			end
		end

		context 'required attributes' do
			class TestRequiredClass < DSLObject
				attribute :required_string,
									:required => true
			end

			before do
				@example = TestRequiredClass.new
			end

			it 'should not validate without specified attribute' do
				expect {
					@example.validate
				}.to raise_error
			end

			it 'should validate with specified attribute' do
				@example.required_string = 'abc'

				expect {
					@example.validate
				}.to_not raise_error
			end
		end

		context 'auto conversion' do
			class TestAutoClass < DSLObject
				attribute :simple,
									types:        [Date],
									auto_convert: { String => Date }

				attribute :lambda,
									types:        [Fixnum],
									auto_convert: { String => lambda { |str| str.to_i } }

				attribute :multi,
									auto_convert: { [Fixnum, Regexp] => lambda { |str| str.to_s } }
			end

			before do
				@sut = TestAutoClass.new
			end

			context '#simple' do
				it 'converse string into date' do
					@sut.simple = '11. 10. 2014'

					expect(@sut.simple).to eq Date.new(2014, 10, 11)
				end
			end

			context '#lambda' do
				it 'converse string into number' do
					@sut.lambda = '1'

					expect(@sut.lambda).to eq 1
				end
			end

			context '#multi' do
				it 'converse number into string' do
					@sut.multi = 1
					expect(@sut.multi).to eq '1'
				end

				it 'converse regexp into string' do
					@sut.multi = /^some text$/
					expect(@sut.multi).to be_kind_of String
					expect(@sut.multi).to include 'some text'
				end
			end
		end
	end
end
