module EventFramework
  # https://github.com/envato/forked/blob/967afd253e1235c49c033992cc9e7f5fae583733/lib/forked/retry_strategies/exponential_backoff.rb
  class ExponentialBackoff
    BACKOFF_FACTOR = 2

    def initialize(logger:, on_error:)
      @logger = logger
      @on_error = on_error
    end

    def run(ready_to_stop)
      tries = 0
      begin
        yield
      rescue StandardError => e
        tries += 1
        sleep_seconds = BACKOFF_FACTOR**tries
        @logger.error("#{e.class} #{e.message}")
        @logger.info("#{e.class} sleeping for #{sleep_seconds} seconds")
        @on_error.call(e, tries)
        sleep_seconds.times do
          ready_to_stop.call
          sleep 1
        end
        retry
      end
    end
  end
end
