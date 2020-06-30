require "event_framework/with_graceful_shutdown"

module EventFramework
  RSpec.describe WithGracefulShutdown do
    let(:logger) { Logger.new("/dev/null") }

    def run(&block)
      described_class.run(logger: logger, &block)
    end

    it "calls the block" do
      called = false
      run do |_ready_to_stop|
        called = true
      end
      expect(called).to eq true
    end

    it "stops the block when the block is called" do
      with_graceful_shutdown = WithGracefulShutdown.new(logger: logger)
      with_graceful_shutdown.shutdown

      after_stop_called = false
      with_graceful_shutdown.run do |ready_to_stop|
        loop do
          ready_to_stop.call
          after_stop_called = true
        end
      end
      expect(after_stop_called).to eq false
    end

    it "exits gracefully after receiving a SIGTERM" do
      @pid = fork {
        run do |ready_to_stop|
          loop do
            ready_to_stop.call
            sleep 0.1
          end
        end
        # This is needed to prevent this forked process from continuing it"s own
        # spec run after it"s been killed by it"s parent
        at_exit { exit! }
      }
      sleep 0.1 # allow time for signals to be trapped in forked process
      Process.kill("TERM", @pid)
      wait_for_pid(@pid, timeout: 2)
    end

    it "resets signal handlers" do
      orig_term = Signal.trap(:TERM) { 42 }
      with_graceful_shutdown = WithGracefulShutdown.new(logger: logger)
      with_graceful_shutdown.run { |ready_to_stop| }
      next_term = Signal.trap(:TERM) { 43 }
      expect(next_term.call).to eq 42
    ensure
      Signal.trap(:TERM, orig_term)
    end

    def wait_for_pid(pid, timeout:)
      Timeout.timeout(timeout) do
        Process.wait(pid)
      end
    rescue Timeout::Error
      Process.kill("KILL", pid)
      raise "failed to stop gracefully"
    end
  end
end
