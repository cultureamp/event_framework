Sequel.migration do
  up do
    create_table :bookmarks do
      column :id, :bigserial, primary_key: true
      column :name, :text, unique: true, null: false
      column :sequence, :bigint, null: false
    end
  end
end
