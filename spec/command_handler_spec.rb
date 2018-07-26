require 'spec_helper'

module EventFramework
  RSpec.describe CommandHandler do
    let(:user_id) { SecureRandom.uuid }
    let(:account_id) { SecureRandom.uuid }
    let(:aggregate_id) { SecureRandom.uuid }

    describe '#with_aggregate' do
      thing_command_handler = Class.new(described_class) do
        def handle(aggregate_id:, command:)
          with_aggregate(Thing, aggregate_id) do |thing|
            thing.do_thing(foo: command.foo)
          end
        end
      end

      it 'handles events' do
        command = double :command, foo: 42
        aggregate = double :aggregate
        repository = double :repository
        thing = class_double("Thing").as_stubbed_const

        allow(repository).to receive(:load_aggregate)
          .with(Thing, aggregate_id)
          .and_return(aggregate)

        expect(aggregate).to receive(:do_thing)
          .with(foo: 42)

        expect(repository).to receive(:save) do |actual_aggregate, metadata|
          expect(actual_aggregate).to eq aggregate
          expect(metadata.user_id).to eq user_id
          expect(metadata.account_id).to eq account_id
        end

        handler = thing_command_handler.new(
          user_id: user_id,
          account_id: account_id,
          repository: repository,
        )
        handler.handle(aggregate_id: aggregate_id, command: command)
      end
    end
  end
end
