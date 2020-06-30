Sequel.migration do
  change do
    run 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'

    create_table :events do
      column :sequence, :bigserial, primary_key: true
      column :aggregate_sequence, :bigint, null: false
      column :id, :uuid, unique: true, null: false, default: Sequel.lit("uuid_generate_v4()")
      column :aggregate_id, :uuid, null: false
      column :aggregate_type, :varchar, null: false
      column :event_type, :varchar, null: false
      column :body, :jsonb, null: false
      column :created_at, :timestamptz, null: false, default: Sequel.lit("now()")
      column :metadata, :jsonb, null: false

      index [:aggregate_id, :aggregate_sequence], unique: true
    end

    create_table :events_sequence_stats do
      column :max_sequence, :bigint, null: false
      column :aggregate_type, :varchar, null: false
      column :event_type, :varchar, null: false
    end

    add_index :events_sequence_stats, [:aggregate_type, :event_type], unique: true

    run(<<~SQL)
      CREATE OR REPLACE FUNCTION refresh_events_sequence_stats()
      RETURNS TRIGGER LANGUAGE plpgsql
      AS $$
      BEGIN

      INSERT INTO events_sequence_stats(event_type, aggregate_type, max_sequence)
      VALUES(NEW.event_type, NEW.aggregate_type, NEW.sequence)
      ON CONFLICT(event_type, aggregate_type) DO
      UPDATE SET max_sequence = NEW.sequence;

      RETURN NULL;
      END $$;
    SQL

    run(<<~SQL)
      DROP TRIGGER IF EXISTS refresh_events_sequence_stats ON events;
      CREATE TRIGGER refresh_events_sequence_stats
      AFTER INSERT ON events
      FOR EACH ROW
      EXECUTE PROCEDURE refresh_events_sequence_stats();
    SQL
  end
end
