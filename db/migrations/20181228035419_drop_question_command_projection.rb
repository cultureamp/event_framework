Sequel.migration do
  up do
    drop_table :question_command_projection
  end

  down do
    create_table :question_command_projection do
      column :question_id, :uuid, unique: true, null: false
      column :survey_id, :uuid, null: false
    end
  end
end
