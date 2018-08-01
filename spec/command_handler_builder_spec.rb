module EventFramework
  RSpec.describe CommandHandlerBuilder do
    class StubMetadata
      attr_reader :user_id, :account_id, :correlation_id

      def initialize(user_id:, account_id:, correlation_id:)
        @user_id = user_id
        @account_id = account_id
        @correlation_id = correlation_id
      end
    end

    # every CommandHandler can be instantiated with a Metadata object
    class StubHandler
      attr_reader :metadata

      def initialize(metadata:)
        @metadata = metadata
      end
    end

    class StubController
      include CommandHandlerBuilder::Buildable

      # these methods are stubbed out by partial doubles in our specs
      def application_user_id; end

      def application_account_id; end

      def params; end

      def handler
        build_handler StubHandler
      end
    end

    before do
      described_class.enable_test_interface
      described_class.configure do |c|
        c.metadata_class = StubMetadata
      end
    end

    after do
      described_class.reset_config
    end

    let(:controller_instance) { StubController.new }

    describe '#build_handler' do
      let(:user_id)    { SecureRandom.uuid }
      let(:account_id) { SecureRandom.uuid }
      let(:request_id) { SecureRandom.uuid }

      let(:handler) { controller_instance.handler }

      context 'if no request_id is available in the controller' do
        it 'raises an error' do
          expect { handler }.to raise_error(described_class::MissingRequestIdError)
        end
      end

      context 'when all the required data is available' do
        before do
          described_class.configure do |c|
            c.user_id_resolver = -> { application_user_id }
            c.account_id_resolver = -> { application_account_id }
            c.request_id_resolver = -> { params.fetch(:request_id) }
          end

          allow(controller_instance).to receive(:application_user_id).and_return(user_id)
          allow(controller_instance).to receive(:application_account_id).and_return(account_id)
          allow(controller_instance).to receive(:params).and_return(request_id: request_id)
        end

        it 'pre-seeds controller#user_id into metadata#user_id of a new command handler' do
          expect(handler.metadata).to have_attributes(user_id: user_id)
        end

        it 'pre-seeds controller#account_id into metadata#account_id of a new command handler' do
          expect(handler.metadata).to have_attributes(account_id: account_id)
        end

        it 'pre-seeds controller#request_id into metadata#correlation_id of a new command handler' do
          expect(handler.metadata).to have_attributes(correlation_id: request_id)
        end
      end
    end
  end
end
