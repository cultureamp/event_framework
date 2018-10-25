Sequel.migration do
  change do
    create_table :question_command_projection_b_surveys do
      column :survey_id, :uuid, unique: true, null: false
      column :account_id, :uuid
    end
  end
end
