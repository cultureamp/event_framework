Sequel.migration do
  change do
    create_table :survey_detail_surveys do
      column :survey_id, :uuid, null: false, unique: true
      column :survey_capture_layout_id, :uuid, unique: true
      column :name, :jsonb, null: false
    end

    create_table :survey_detail_sections do
      column :section_id, :uuid, null: false, unique: true
      column :survey_id, :uuid, null: false
      column :order, :integer, null: false
      column :name, :jsonb, null: false
      column :short_description, :jsonb, null: false
      column :long_description, :jsonb, null: false

      # TODO: index [:survey_id, :section_id]
    end

    create_table :survey_detail_questions do
      column :survey_id, :uuid, null: false
      column :question_id, :uuid, null: false, unique: true
      column :section_id, :uuid
      column :order, :integer
      column :mandatory, :boolean, null: false
      column :question_type, :text, null: false
      column :code, :text, null: false
      column :text, :jsonb, null: false
      column :scale, :text, null: false
      column :other_option, :boolean, null: false
      column :selection_limit, :integer, null: false

      # TODO: index [:survey_id, :question_id]
    end

    create_table :survey_detail_select_options do
      column :select_option_id, :uuid, null: false, unique: true
      column :question_id, :uuid, null: false
      column :value, :jsonb, null: false

      # TODO: index [:question_id, :select_option_id]
    end
  end
end
