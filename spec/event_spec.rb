module EventFramework
  RSpec.describe Event do
    describe "Metadata" do
      it "requires a user_id" do
        expect {
          Event::Metadata.new(
            account_id: SecureRandom.uuid,
            user_id: SecureRandom.uuid
          )
        }.to_not raise_error

        expect {
          Event::Metadata.new(
            account_id: SecureRandom.uuid,
            user_id: SecureRandom.uuid,
            metadata_type: :unattributed
          )
        }.to raise_error(include("invalid type for :metadata_type"))

        expect {
          Event::Metadata.new(
            account_id: SecureRandom.uuid
          )
        }.to raise_error(include(":user_id is missing in"))

        expect {
          Event::Metadata.new(
            account_id: SecureRandom.uuid,
            user_id: nil
          )
        }.to raise_error(include("invalid type for :user"))
      end

      describe ".new_with_fallback" do
        context "with valid Metadata args" do
          it "returns a Metadata object" do
            expect(
              Event::Metadata.new_with_fallback(
                fallback_class: Event::SystemMetadata,
                account_id: SecureRandom.uuid,
                user_id: SecureRandom.uuid
              )
            ).to be_a(Event::Metadata)
          end
        end

        context "with invalid Metadata args" do
          it "returns a SystemMetadata object" do
            expect(
              Event::Metadata.new_with_fallback(
                fallback_class: Event::SystemMetadata,
                account_id: SecureRandom.uuid,
                user_id: "invalid"
              )
            ).to be_a(Event::SystemMetadata)
          end
        end

        context "with invalid Metadata and fallback_class args" do
          it "raises an exception" do
            expect {
              Event::Metadata.new_with_fallback(
                fallback_class: Event::SystemMetadata,
                account_id: SecureRandom.uuid,
                user_id: "invalid",
                also: "invalid"
              )
            }.to raise_error(include("unexpected keys [:also] in Hash input"))
          end
        end
      end
    end

    describe "UnattributedMetadata" do
      it "does not allow a user_id" do
        expect {
          Event::UnattributedMetadata.new(
            account_id: SecureRandom.uuid
          )
        }.to_not raise_error

        expect {
          Event::UnattributedMetadata.new(
            account_id: SecureRandom.uuid,
            metadata_type: :attributed
          )
        }.to raise_error(include("invalid type for :metadata_type"))

        expect {
          Event::UnattributedMetadata.new(
            account_id: SecureRandom.uuid,
            user_id: SecureRandom.uuid
          )
        }.to raise_error(include("unexpected keys [:user_id]"))
      end
    end
  end
end
