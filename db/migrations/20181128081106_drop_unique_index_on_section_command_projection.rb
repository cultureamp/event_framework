Sequel.migration do
  change do
    alter_table :section_command_projection do
      drop_constraint :section_command_projection_survey_capture_layout_id_key, type: :unique
    end
  end
end
