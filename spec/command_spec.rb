module EventFramework
  RSpec.describe Command do
    let(:command_class) do
      Class.new(Command) do
        attribute :foo, Types::Strict::String
        attribute :bar, Types::Strict::Integer

        validation_schema do
          required(:foo).filled(:str?)
          required(:bar).filled(:int?)
        end
      end
    end

    describe '.validate' do
      context 'with valid input' do
        it 'returns a successful result object' do
          expect(command_class.validate('foo' => 'qux', bar: 42)).to be_success
        end
      end

      context 'with invalid input' do
        let(:params) do
          {
            'foo' => Object.new,
            bar: 'fourty two',
          }
        end

        it 'returns a failed result object' do
          expect(command_class.validate(params)).to be_failure
        end

        it 'returns errors' do
          expect(command_class.validate(params).errors).to eq(
            foo: ['must be a string'],
            bar: ['must be an integer'],
          )
        end
      end
    end
  end
end
