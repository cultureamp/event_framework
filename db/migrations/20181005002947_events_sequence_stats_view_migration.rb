Sequel.migration do
  up do
    dataset = from(:events)
      .select(:aggregate_type, :event_type)
      .select_more { max(:sequence).as(:max_sequence) }
      .group_by(:aggregate_type, :event_type)

    create_view(:events_sequence_stats, dataset, materialized: true)
  end
end
