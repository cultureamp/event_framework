module EventFramework
  RSpec.describe EventProcessorSupervisor::OnForkedError do
    describe "#call" do
      let(:logger) { instance_double(Logger) }
      subject(:on_forked_error) { described_class.new("EventProcessorName") }

      before do
        allow(Logger).to receive(:new).with(STDOUT).and_return(logger)
      end

      it "logs the error" do
        expect(logger).to receive(:error).with(
          msg: "the roof",
          event_processor: "EventProcessorName",
          error: "RuntimeError",
          tries: 42
        )

        on_forked_error.call(RuntimeError.new("the roof"), 42)
      end
    end
  end
end
