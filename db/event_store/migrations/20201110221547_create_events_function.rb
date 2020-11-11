Sequel.migration do
  # TODO: Use sequel's create_function
  up do
    run(<<~SQL)
      CREATE OR REPLACE FUNCTION insert_events(
        _aggregateId uuid,
        _eventTypes text[],
        _aggregateTypes text[],
        _aggregateSequences int[],
        _bodies jsonb[],
        _metadatas jsonb[],
        _lockTimeoutMilliseconds int
      ) RETURNS SETOF events as $$
        DECLARE
          aggregate_sequence int;
          index int := 1;
        BEGIN
          -- Set a local lock_timeout within a transaction then get an exclusive
          -- advisory lock so that we're the only database connection that can
          -- sink an event.
          --
          -- If you're modifing the locking logic you can test that it's working
          -- correctly using the ./bin/demonstrate_event_sequence_id_gaps script.
          EXECUTE 'SET LOCAL lock_timeout TO ' || _lockTimeoutMilliseconds;
          PERFORM pg_advisory_xact_lock(-1);

          foreach aggregate_sequence IN ARRAY(_aggregateSequences)
            loop
              RETURN QUERY INSERT INTO EVENTS
                (aggregate_id, aggregate_sequence, event_type, aggregate_type, body, metadata)
              VALUES
                (
                  _aggregateId,
                  _aggregateSequences[index],
                  _eventTypes[index],
                  _aggregateTypes[index],
                  _bodies[index],
                  _metadatas[index]
                )
              RETURNING *;
              index := index + 1;
            end loop;

          RETURN;
        END;
      $$ language plpgsql;
    SQL
  end
end
