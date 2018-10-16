Sequel.migration do
  up do
    dataset = from(:events)
      .select(:aggregate_type, :event_type)
      .select_more { max(:sequence).as(:max_sequence) }
      .group_by(:aggregate_type, :event_type)

    create_view(:events_sequence_stats, dataset, materialized: true)

    add_index(:events_sequence_stats, [:aggregate_type, :event_type], unique: true)

    run(<<~SQL)
      CREATE FUNCTION refresh_events_sequence_stats()
      RETURNS TRIGGER LANGUAGE plpgsql
      AS $$
      BEGIN
      REFRESH MATERIALIZED VIEW CONCURRENTLY events_sequence_stats;
      RETURN NULL;
      END $$;
    SQL

    run(<<~SQL)
      CREATE TRIGGER refresh_events_sequence_stats
      AFTER INSERT
      ON events
      FOR EACH STATEMENT
      EXECUTE PROCEDURE refresh_events_sequence_stats();
    SQL
  end
end
