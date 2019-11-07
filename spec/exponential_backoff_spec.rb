require "event_framework/exponential_backoff"

module EventFramework
  RSpec.describe ExponentialBackoff do
    TestError = Class.new(StandardError)

    let(:ready_to_stop) { -> {} }
    let(:logger) { instance_double(Logger, error: nil, info: nil) }
    let(:on_error) { instance_double(Proc, call: nil) }
    let(:raise_on_first_block) do
      tries = 0
      proc do
        if tries == 0
          tries += 1
          raise TestError
        end
        tries += 1
        tries
      end
    end
    subject(:exponential_backoff) { described_class.new(logger: logger, on_error: on_error) }

    before do
      def exponential_backoff.sleep(seconds); end
    end

    it "returns the result of the block" do
      return_value = exponential_backoff.run(ready_to_stop) { 42 }
      expect(return_value).to eq 42
    end

    it "calls on_error on error then returns" do
      return_value = exponential_backoff.run(-> {}) do
        raise_on_first_block.call
        42
      end
      expect(on_error).to have_received(:call).with(an_instance_of(TestError), 1)
      expect(return_value).to eq 42
    end

    it "logs the error" do
      begin
        exponential_backoff.run(-> {}) { raise_on_first_block.call }
      rescue StandardError
        TestError
      end
      expect(logger).to have_received(:error)
      expect(logger).to have_received(:info)
    end

    it "calls ready to stop each second interval" do
      ready_to_stop = instance_double(Proc, call: nil)
      exponential_backoff.run(ready_to_stop) { raise_on_first_block.call }
      expect(ready_to_stop).to have_received(:call).twice
    end

    it "sleeps with exponential backoff" do
      tries = 0
      raise_twice_block = proc do
        if tries < 3
          tries += 1
          raise TestError
        end
        tries += 1
        tries
      end
      expect(exponential_backoff).to receive(:sleep).with(1).exactly(14).times
      # 2 seconds first error, 4 seconds second error, 8 times third error, which is 14 total
      exponential_backoff.run(-> {}) { raise_twice_block.call }
    end

    it "sleeps with exponential backoff with a cap" do
      tries = 0
      raise_9_times_block = proc do
        if tries < 10
          tries += 1
          raise TestError
        end
        tries += 1
        tries
      end
      exponential_backoff.run(-> {}) { raise_9_times_block.call }

      # We'll sleep for 2, 4, 8, ..., 128, 256, 300, 300
      expect(logger).to have_received(:info).with(/sleeping for 256 seconds/)
      expect(logger).to have_received(:info).with(/sleeping for 300 seconds/).twice
    end
  end
end
