Sequel.migration do
  change do
    create_table :survey_detail_surveys do
      column :survey_id, :uuid, null: false, unique: true
      column :survey_capture_layout_id, :uuid, unique: true
      column :name, :text, null: false
    end
  end
end
