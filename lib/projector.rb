module EventFramework
  # A Projector is a type of EventProcessor.
  #
  # It handles events passed to it, typically by a EventProcessorSupervisor.
  #
  # We can wrap the processing of a batch of events inside a transaction to
  # speed up our database operations.
  class Projector < EventProcessor
  end
end
