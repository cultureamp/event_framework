require "logger"

module EventFramework
  # Traps SIGTERM and SIGINT and shuts down only when the block
  # is called, allowing for graceful shutdown.
  #
  # Example:
  #
  #     WithGracefulShutdown.run do |ready_to_stop|
  #       loop do
  #         # do some work
  #         ready_to_stop.call
  #       end
  #     end
  #
  # https://github.com/envato/forked/blob/967afd253e1235c49c033992cc9e7f5fae583733/lib/forked/with_graceful_shutdown.rb
  class WithGracefulShutdown
    def self.run(logger: Logger.new(STDOUT), &block)
      new(logger: logger).run(&block)
    end

    def initialize(logger:)
      @logger = logger
      @shutdown = false
    end

    def run
      trap_shutdown_signals do
        catch(:stop) do
          ready_to_stop = -> { stop_if_necessary }
          yield ready_to_stop
        end
      end
    end

    def stop_if_necessary
      if @shutdown
        @logger.info("Shutting down")
        throw :stop
      end
    end

    def shutdown
      @shutdown = true
    end

    private

    def trap_shutdown_signals
      orig_int_handler = Signal.trap(:INT) { shutdown }
      orig_term_handler = Signal.trap(:TERM) { shutdown }
      yield
    ensure
      Signal.trap(:INT, orig_int_handler)
      Signal.trap(:TERM, orig_term_handler)
    end
  end
end
