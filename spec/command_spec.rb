module EventFramework
  RSpec.describe Command do
    describe "#aggregate_id" do
      it "must be present" do
        expect { described_class.new }
          .to raise_error(Dry::Struct::Error, /aggregate_id/)
      end

      it "must be a UUID" do
        expect { described_class.new(aggregate_id: "507f191e810c19729de860ea") }
          .to raise_error(Dry::Struct::Error, /aggregate_id/)
      end
    end

    describe ".validation_schema" do
      let(:command_class) do
        Class.new(Command) do
          validation_schema do
          end
        end
      end

      it "automatically includes aggregate_id" do
        expect(command_class.validate(aggregate_id: SecureRandom.uuid)).to be_a_success
      end
    end

    describe ".validate" do
      context "with no defined schema" do
        let(:command_class) do
          Class.new(Command) do
            attribute :foo, Types::Strict::String
            attribute :bar, Types::Strict::Integer
          end
        end

        it "raises an error" do
          expect { command_class.validate({}) }.to raise_error(Command::ValidationNotImplementedError)
        end
      end

      context "with a defined schema" do
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

        context "when given valid input" do
          let(:params) do
            {:aggregate_id => SecureRandom.uuid, "foo" => "qux", :bar => 42}
          end

          it "returns a successful result object" do
            expect(command_class.validate(params)).to be_a_success
          end
        end

        context "when given invalid input" do
          let(:params) do
            {:aggregate_id => SecureRandom.uuid, "foo" => Object.new, :bar => "fourty two"}
          end

          it "returns a failed result object" do
            expect(command_class.validate(params)).to be_a_failure
          end

          it "returns errors" do
            expect(command_class.validate(params).errors).to eq(
              foo: ["must be a string"],
              bar: ["must be an integer"]
            )
          end
        end
      end
    end

    describe ".build" do
      context "with no defined schema" do
        let(:command_class) do
          Class.new(Command) do
            attribute :foo, Types::Strict::String
            attribute :bar, Types::Strict::Integer
          end
        end

        it "raises an error" do
          expect { command_class.build({}) }.to raise_error(Command::ValidationNotImplementedError)
        end
      end

      context "with a defined schema" do
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

        context "when given valid input" do
          let(:params) do
            {:aggregate_id => SecureRandom.uuid, "foo" => "qux", :bar => 42}
          end

          it "returns a successful result object" do
            expect(command_class.build(params)).to be_a_success
          end
        end

        context "when given invalid input" do
          let(:params) do
            {:aggregate_id => SecureRandom.uuid, "foo" => Object.new, :bar => "fourty two"}
          end

          it "returns a failed result object" do
            expect(command_class.build(params)).to be_a_failure
          end

          it "returns errors" do
            expect(command_class.build(params).failure).to eq [
              :validation_failed,
              {
                foo: ["must be a string"],
                bar: ["must be an integer"]
              }
            ]
          end
        end
      end
    end
  end
end
