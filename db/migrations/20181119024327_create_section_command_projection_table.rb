Sequel.migration do
  change do
    create_table :section_command_projection do
      column :section_id, :uuid, null: false, unique: true
      column :survey_capture_layout_id, :uuid, null: false, unique: true
      column :status, :text, null: false
      column :intended_purpose, :text, null: false
    end
  end
end
