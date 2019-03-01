Sequel.migration do
  up do
    create_table :question_command_projection_a_surveys do
      column :survey_id, :uuid, unique: true, null: false
      column :account_id, :uuid
    end

    create_table :question_command_projection_a do
      column :question_id, :uuid, unique: true, null: false
      column :survey_id, :uuid, null: false
      column :account_id, :uuid
    end
  end
end
