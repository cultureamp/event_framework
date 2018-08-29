Sequel.migration do
  up do
    add_index :events, [:aggregate_type, :event_type]
  end
end
