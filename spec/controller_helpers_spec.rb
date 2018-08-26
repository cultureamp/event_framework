module EventFramework
  RSpec.describe ControllerHelpers do
    class StubMetadata
      attr_reader :user_id, :account_id, :correlation_id

      def initialize(user_id:, account_id:, correlation_id:)
        @user_id = user_id
        @account_id = account_id
        @correlation_id = correlation_id
      end
    end

    class StubController
      include ControllerHelpers::MetadataHelper
      include ControllerHelpers::CommandHelper

      # these methods are stubbed out by partial doubles in our specs
      def application_user_id; end

      def application_account_id; end

      def params; end
    end

    # `enable_test_interface`and `reset_config` are methods added by
    # `dry/configurable` to make what we're doing really easy.
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

    describe 'MetadataHelper#build_metadata' do
      let(:user_id)    { SecureRandom.uuid }
      let(:account_id) { SecureRandom.uuid }
      let(:request_id) { SecureRandom.uuid }

      let(:metadata) { controller_instance.build_metadata }

      context 'if no request_id is available in the controller' do
        it 'raises an error' do
          expect { metadata }.to raise_error(described_class::MetadataHelper::MissingRequestIdError)
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

        it 'pre-seeds controller#user_id into the user_id attribute of a new metadata instance' do
          expect(metadata).to have_attributes(user_id: user_id)
        end

        it 'pre-seeds controller#account_id into the account_id attribute of a new metadata instance' do
          expect(metadata).to have_attributes(account_id: account_id)
        end

        it 'pre-seeds controller#request_id into the correlation_id attribute of a new metadata instance' do
          expect(metadata).to have_attributes(correlation_id: request_id)
        end
      end
    end

    describe 'CommandHelper#validate_params_for_command' do
      let(:command) { class_double "Command" }
      let(:result)  { instance_double "Dry::Validation::Result" }
      let(:params)  { double :params }

      def perform_validation
        controller_instance.validate_params_for_command(params, command)
      end

      before do
        allow(command).to receive(:validate).with(params).and_return(result)
      end

      context 'and the params validate against the command schema' do
        before { allow(result).to receive(:success?).and_return(true) }

        it 'returns the result of the validation' do
          perform_validation

          expect(result).to be_a_success
        end
      end

      context 'and the params fail validation' do
        before { allow(result).to receive(:failure?).and_return(true) }

        it 'returns the result of the validation' do
          perform_validation

          expect(result).to be_a_failure
        end
      end
    end
  end
end
