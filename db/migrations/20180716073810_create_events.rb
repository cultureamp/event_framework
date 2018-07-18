Sequel.migration do
  change do
    create_table(:events) do
      column :sequence_id, :bigserial, primary_key: true
      column :id, :uuid, unique: true, null: false
      column :aggregate_id, :uuid, null: false
      column :type, :varchar, null: false
      column :body, :json, null: false
      column :created_at, :timestamptz, null: false, default: Sequel.lit("now()")
    end
  end
end
