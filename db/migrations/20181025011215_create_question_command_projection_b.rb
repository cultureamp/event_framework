Sequel.migration do
  change do
    create_table :question_command_projection_b do
      column :question_id, :uuid, unique: true, null: false
      column :survey_id, :uuid, null: false
      column :account_id, :uuid
    end
  end
end
