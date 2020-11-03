module EventFramework
  RSpec.describe CommandHandler do
    let(:user_id) { SecureRandom.uuid }
    let(:account_id) { SecureRandom.uuid }
    let(:aggregate_id) { SecureRandom.uuid }

    let(:metadata) do
      double :metadata, user_id: user_id, account_id: account_id
    end

    let(:repository) { instance_spy "Repository" }
    let(:instance) { described_class.new(repository: repository) }

    describe "#metadata" do
      it "is private" do
        expect { instance.metadata }
          .to raise_error(NoMethodError, /private method(.*)metadata/)
      end
    end

    describe "#with_aggregate" do
      let(:aggregate) { double :aggregate }
      let(:repository) { instance_spy "Repository", load_aggregate: aggregate }
      let(:thing_class) { class_double "Thing" }

      let(:empty_block) { ->(aggregate) {} }

      it "is private" do
        expect { instance.with_aggregate(thing_class, aggregate_id, &empty_block) }
          .to raise_error(NoMethodError, /private method(.*)with_aggregate/)
      end

      it "loads an aggregate from the repository" do
        instance.send(:with_aggregate, thing_class, aggregate_id, &empty_block)

        expect(repository).to have_received(:load_aggregate).with(thing_class, aggregate_id)
      end

      it "yields the aggregate to a block" do
        expect { |b| instance.send(:with_aggregate, thing_class, aggregate_id, &b) }
          .to yield_with_args(aggregate)
      end

      it "saves the aggregate" do
        instance.instance_variable_set(:@metadata, metadata)
        instance.send(:with_aggregate, thing_class, aggregate_id, &empty_block)

        expect(repository).to have_received(:save_aggregate).with(aggregate, metadata: metadata)
      end
    end

    describe "#with_new_aggregate" do
      let(:aggregate) { double :aggregate }
      let(:repository) { instance_spy "Repository", new_aggregate: aggregate }
      let(:thing_class) { class_double "Thing" }

      let(:instance) do
        described_class.new(repository: repository)
      end

      let(:empty_block) { ->(aggregate) {} }

      it "is private" do
        expect { instance.with_new_aggregate(thing_class, aggregate_id, &empty_block) }
          .to raise_error(NoMethodError, /private method(.*)with_new_aggregate/)
      end

      it "loads an aggregate from the repository" do
        instance.send(:with_new_aggregate, thing_class, aggregate_id, &empty_block)

        expect(repository).to have_received(:new_aggregate).with(thing_class, aggregate_id)
      end

      it "yields the aggregate to a block" do
        expect { |b| instance.send(:with_new_aggregate, thing_class, aggregate_id, &b) }
          .to yield_with_args(aggregate)
      end

      it "saves the aggregate ensuring it is a new aggregate" do
        instance.instance_variable_set(:@metadata, metadata)
        instance.send(:with_new_aggregate, thing_class, aggregate_id, &empty_block)

        expect(repository).to have_received(:save_aggregate).with(aggregate, metadata: metadata, ensure_new_aggregate: true)
      end
    end

    describe "#with_new_or_existing_aggregate" do
      let(:aggregate) { double :aggregate }
      let(:repository) { instance_spy "Repository", new_or_existing_aggregate: aggregate }
      let(:thing_class) { class_double "Thing" }

      let(:instance) do
        described_class.new(repository: repository)
      end

      let(:empty_block) { ->(aggregate) {} }

      it "is private" do
        expect { instance.with_new_or_existing_aggregate(thing_class, aggregate_id, &empty_block) }
          .to raise_error(NoMethodError, /private method(.*)with_new_or_existing_aggregate/)
      end

      it "loads an aggregate from the repository" do
        instance.send(:with_new_or_existing_aggregate, thing_class, aggregate_id, &empty_block)

        expect(repository).to have_received(:new_or_existing_aggregate).with(thing_class, aggregate_id)
      end

      it "yields the aggregate to a block" do
        expect { |b| instance.send(:with_new_or_existing_aggregate, thing_class, aggregate_id, &b) }
          .to yield_with_args(aggregate)
      end

      it "saves the aggregate" do
        instance.instance_variable_set(:@metadata, metadata)
        instance.send(:with_new_or_existing_aggregate, thing_class, aggregate_id, &empty_block)

        expect(repository).to have_received(:save_aggregate).with(aggregate, metadata: metadata)
      end
    end

    describe "#call" do
      after do
        described_class.instance_variable_set(:@handler_proc, nil)
        described_class.instance_variable_set(:@command_class, nil)
      end

      context "when command_class is not defined" do
        it "raises a NotImplementedError" do
          described_class.instance_variable_set(:@handler_proc, "foo")
          expect { described_class.new(repository: repository).call(command: nil, metadata: nil) }
            .to raise_error(NotImplementedError)
        end
      end

      context "when handler_proc is not defined" do
        it "raises a NotImplementedError" do
          described_class.instance_variable_set(:@command_class, NilClass)
          expect { described_class.new(repository: repository).call(command: nil, metadata: nil) }
            .to raise_error(NotImplementedError)
        end
      end

      context "when command is a sub-class of @command_class" do
        let(:superclass) { String }
        let(:subclass) { Class.new(superclass) }
        let(:command) { subclass.new }

        it "accepts the command" do
          described_class.instance_variable_set(:@command_class, superclass)
          described_class.instance_variable_set(:@handler_proc, ->(_, _) { :success })
          expect(described_class.new(repository: repository).call(command: command, metadata: nil))
            .to eql :success
        end
      end

      context "when command is not of the correct type" do
        it "raises a MismatchedCommand error" do
          described_class.instance_variable_set(:@command_class, FalseClass)
          described_class.instance_variable_set(:@handler_proc, ->(_, _) {})
          expect { described_class.new(repository: repository).call(command: nil, metadata: nil) }
            .to raise_error(EventFramework::CommandHandler::MismatchedCommandError)
        end
      end

      describe "when handler_proc#call fails" do
        # Given that we can't pass an RSpec double to instance_exec (grrr), we need
        # a Proc that can track how many times it has been called.
        let!(:handler_proc) do
          proc do |_, _|
            @attempt_count ||= 0

            if @attempt_count < 4
              @attempt_count += 1
              raise RetriableException
            end
          end
        end

        let(:command_class) { Class.new }
        let(:command_instance) { command_class.new }
        let(:instance) { described_class.new(repository: instance_spy("Repository")) }

        before do
          described_class.instance_variable_set(:@command_class, command_class)
          described_class.instance_variable_set(:@handler_proc, handler_proc)
        end

        context "if the failure threshold has not been reached" do
          before do
            stub_const "#{described_class.name}::FAILURE_RETRY_THRESHOLD", 100
            stub_const "#{described_class.name}::FAILURE_RETRY_SLEEP_INTERVAL", 0
          end

          it "calls handler_proc until it passes" do
            expect { instance.call(command: command_instance, metadata: nil) }.not_to raise_error

            expect(instance.instance_variable_get(:@attempt_count)).to eql 4
          end
        end

        context "if the failure count threshold has been reached" do
          before do
            stub_const "#{described_class.name}::FAILURE_RETRY_THRESHOLD", 1
          end

          it "raises an error" do
            expect { instance.call(command: command_instance, metadata: nil) }
              .to raise_error(RetriableException)

            expect(instance.instance_variable_get(:@attempt_count)).to eql 1
          end
        end
      end
    end

    describe "#command_class" do
      let(:instance) { described_class.new(repository: instance_spy("Repository")) }

      it "is private" do
        expect { instance.command_class }.to raise_error NoMethodError, /private method(.*)command_class/
      end
    end

    describe "#handler_proc" do
      let(:instance) { described_class.new(repository: instance_spy("Repository")) }

      it "is private" do
        expect { instance.handler_proc }.to raise_error NoMethodError, /private method(.*)handler_proc/
      end
    end
  end
end
