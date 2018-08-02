module EventFramework
  RSpec.describe CommandHandler do
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
      let(:aggregate) { double :aggregate }
      let(:repository) { spy :repository, load_aggregate: aggregate }
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
          expect { described_class.new(metadata: metadata).handle(nil, nil) }
            .to raise_error(NotImplementedError)
        end
      end

      context 'when callable is not defined' do
        it 'raises a NotImplementedError' do
          described_class.instance_variable_set(:@command_class, NilClass)
          expect { described_class.new(metadata: metadata).handle(nil, nil) }
            .to raise_error(NotImplementedError)
        end
      end

      context 'when command is not of the correct type' do
        it 'raises a MismatchedCommand error' do
          described_class.instance_variable_set(:@command_class, FalseClass)
          described_class.instance_variable_set(:@callable, ->(_, _) {})
          expect { described_class.new(metadata: metadata).handle(nil, nil) }
            .to raise_error(EventFramework::CommandHandler::MismatchedCommandError)
        end
      end

      describe 'when callable#call fails' do
        # Given that we can't pass an RSpec double to instance_exec (grrr), we need
        # a Proc that can track how many times it has been called.
        let!(:callable) do
          proc do |_, _|
            @attempt_count ||= 0

            if @attempt_count < 4
              @attempt_count += 1
              raise RetriableException
            end
          end
        end

        let(:command_class) { TrueClass }
        let(:instance) { described_class.new(metadata: metadata) }

        before do
          described_class.instance_variable_set(:@command_class, command_class)
          described_class.instance_variable_set(:@callable, callable)
        end

        context 'if the failure threshold has not been reached' do
          before do
            stub_const "#{described_class.name}::FAILURE_RETRY_THRESHOLD", 100
          end

          it 'calls callable until it passes' do
            expect { instance.handle(nil, true) }.not_to raise_error

            expect(instance.instance_variable_get(:@attempt_count)).to eql 4
          end
        end

        context 'if the failure count threshold has been reached' do
          before do
            stub_const "#{described_class.name}::FAILURE_RETRY_THRESHOLD", 1
          end

          it 'raises an error' do
            expect { instance.handle(nil, true) }
              .to raise_error(described_class::RetryFailureThresholdExceededException)

            expect(instance.instance_variable_get(:@attempt_count)).to eql 1
          end
        end
      end
    end
  end
end
