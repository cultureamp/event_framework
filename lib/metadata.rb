module EventFramework
  class Metadata
    attr_accessor :correlation_id
    attr_accessor :causation_id
    attr_accessor :user_id
    attr_accessor :account_id

    attr_reader :created_at

    def initialize(**args)
      self.correlation_id = args[:correlation_id]
      self.causation_id = args[:causation_id]
      self.user_id = args[:user_id]
      self.account_id = args[:account_id]

      @created_at = args[:created_at]
    end

    def to_h
      {
        correlation_id: correlation_id,
        causation_id: causation_id,
        user_id: user_id,
        account_id: account_id,
        created_at: created_at,
      }
    end
  end
end
