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
	end
end
