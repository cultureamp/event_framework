Sequel.migration do
  change do
    create_table :survey_detail_surveys do
      column :survey_id, :uuid, null: false, unique: true
      column :survey_capture_layout_id, :uuid, unique: true
      column :name, :text, null: false
    end

    create_table :survey_detail_sections do
      column :section_id, :uuid, null: false, unique: true
      column :survey_id, :uuid, null: false
      column :order, :integer, null: false
    end
  end
end
