module EventFramework
  RSpec.describe Event do
    describe "Metadata" do
      it "requires a user_id" do
        expect do
          Event::Metadata.new(
            account_id: SecureRandom.uuid,
            user_id: SecureRandom.uuid,
          )
        end.to_not raise_error

        expect do
          Event::Metadata.new(
            account_id: SecureRandom.uuid,
            user_id: SecureRandom.uuid,
            metadata_type: :unattributed,
          )
        end.to raise_error(include("invalid type for :metadata_type"))

        expect do
          Event::Metadata.new(
            account_id: SecureRandom.uuid,
          )
        end.to raise_error(include(":user_id is missing in"))

        expect do
          Event::Metadata.new(
            account_id: SecureRandom.uuid,
            user_id: nil,
          )
        end.to raise_error(include("invalid type for :user"))
      end
    end

    describe "UnattributedMetadata" do
      it "does not allow a user_id" do
        expect do
          Event::UnattributedMetadata.new(
            account_id: SecureRandom.uuid,
          )
        end.to_not raise_error

        expect do
          Event::UnattributedMetadata.new(
            account_id: SecureRandom.uuid,
            metadata_type: :attributed,
          )
        end.to raise_error(include("invalid type for :metadata_type"))

        expect do
          Event::UnattributedMetadata.new(
            account_id: SecureRandom.uuid,
            user_id: SecureRandom.uuid,
          )
        end.to raise_error(include("unexpected keys [:user_id]"))
      end
    end
  end
end
