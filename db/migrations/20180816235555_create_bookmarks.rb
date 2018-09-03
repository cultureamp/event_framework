Sequel.migration do
  up do
    create_table :bookmarks do
      column :lock_key, :bigserial
      column :name, :text, primary_key: true, unique: true, null: false
      column :sequence, :bigint, null: false
    end
  end
end
