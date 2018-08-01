Sequel.migration do
  change do
    run 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'

    create_table :events do
      column :sequence, :bigserial, primary_key: true
      column :aggregate_sequence, :bigint, null: false
      column :id, :uuid, unique: true, null: false, default: Sequel.lit('uuid_generate_v4()')
      column :aggregate_id, :uuid, null: false
      column :aggregate_type, :varchar, null: false
      column :event_type, :varchar, null: false
      column :body, :jsonb, null: false
      column :metadata, :jsonb, null: false

      index [:aggregate_id, :aggregate_sequence], unique: true
    end
  end
end
