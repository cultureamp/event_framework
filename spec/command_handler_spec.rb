require 'spec_helper'

RSpec.describe EventFramework::CommandHandler do
  let(:user_id) { SecureRandom.uuid }
  let(:account_id) { SecureRandom.uuid }
  let(:aggregate_id) { SecureRandom.uuid }

  let(:metadata) do
    double :metadata, user_id: user_id, account_id: account_id
  end

  describe '#initialize' do
    it 'has a required `metadata` argument' do
      expect { described_class.new }
        .to raise_error(ArgumentError, /metadata/)
    end
  end

  describe '#metadata' do
    let(:instance) { described_class.new(metadata: metadata) }

    it 'is private' do
      expect { instance.metadata }
        .to raise_error(NoMethodError, /private method(.*)metadata/)
    end

    it 'returns the metadata passed in via the initializer' do
      expect(instance.send(:metadata)).to be metadata
    end
  end

  describe '#with_aggregate' do
    let(:aggregate)   { double :aggregate }
    let(:repository)  { spy :repository, load_aggregate: aggregate }
    let(:thing_class) { class_double "Thing" }

    let(:instance) do
      described_class.new(metadata: metadata, repository: repository)
    end

    let(:empty_block) { -> (aggregate) {} }

    it 'is private' do
      expect { instance.with_aggregate(thing_class, aggregate_id, &empty_block) }
        .to raise_error(NoMethodError, /private method(.*)with_aggregate/)
    end

    it 'loads an aggregate from the repository' do
      instance.send(:with_aggregate, thing_class, aggregate_id, &empty_block)

      expect(repository).to have_received(:load_aggregate).with(thing_class, aggregate_id)
    end

    it 'yields the aggregate to a block' do
      expect { |b| instance.send(:with_aggregate, thing_class, aggregate_id, &b) }
        .to yield_with_args(aggregate)
    end
  end

  describe '#handle' do
    after do
      described_class.instance_variable_set(:@callable, nil)
      described_class.instance_variable_set(:@command_class, nil)
    end

    context 'when command_class is not defined' do
      it 'raises a NotImplementedError' do
        described_class.instance_variable_set(:@callable, 'foo')
        expect { described_class.new(metadata: metadata).handle(nil, nil) }.to raise_error(NotImplementedError)
      end
    end

    context 'when callable is not defined' do
      it 'raises a NotImplementedError' do
        described_class.instance_variable_set(:@command_class, NilClass)
        expect { described_class.new(metadata: metadata).handle(nil, nil) }.to raise_error(NotImplementedError)
      end
    end

    context 'when command is not of the correct type' do
      it 'raises a MismatchedCommand error' do
        described_class.instance_variable_set(:@command_class, FalseClass)
        described_class.instance_variable_set(:@callable, ->(_, _) {})
        expect { described_class.new(metadata: metadata).handle(nil, nil) }.to raise_error(EventFramework::CommandHandler::MismatchedCommand)
      end
    end
  end
end
