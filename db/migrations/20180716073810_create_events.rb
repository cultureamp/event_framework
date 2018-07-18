Sequel.migration do
  change do
    run 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'

    create_table(:events) do
      column :sequence_id, :bigserial, primary_key: true
      column :id, :uuid, unique: true, null: false, default: Sequel.lit('uuid_generate_v4()')
      column :aggregate_id, :uuid, null: false
      column :type, :varchar, null: false
      column :body, :json, null: false
      column :created_at, :timestamptz, null: false, default: Sequel.lit("now()")
    end
  end
end
