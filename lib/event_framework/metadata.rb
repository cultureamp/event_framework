module EventFramework
  class Metadata
    attr_accessor :correlation_id
    attr_accessor :causation_id
    attr_accessor :user_id
    attr_accessor :account_id
    # The "bypass_mongo_projection" field is being replaced with "migrated".
    attr_accessor :migrated
    attr_accessor :bypass_mongo_projection

    def initialize(**args)
      self.correlation_id = args[:correlation_id]
      self.causation_id = args[:causation_id]
      self.user_id = args[:user_id]
      self.account_id = args[:account_id]
      self.migrated = args[:migrated]
      self.bypass_mongo_projection = args[:bypass_mongo_projection]
    end

    def to_h
      {
        correlation_id: correlation_id,
        causation_id: causation_id,
        user_id: user_id,
        account_id: account_id,
        migrated: migrated,
        bypass_mongo_projection: bypass_mongo_projection,
      }.delete_if { |_, v| v.nil? }
    end
  end
end
