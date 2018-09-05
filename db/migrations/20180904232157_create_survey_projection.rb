Sequel.migration do
  change do
    create_table :survey_command_projection do
      column :survey_id, :uuid, unique: true, null: false
      column :account_id, :uuid
      column :survey_capture_layout_id, :uuid, unique: true
    end
  end
end
