Sequel.migration do
  up do
    create_table :question_command_projection_a_surveys do
      column :survey_id, :uuid, primary_key: true
      column :account_id, :uuid
    end

    create_table :question_command_projection_a do
      column :question_id, :uuid, primary_key: true
      column :survey_id, :uuid, null: false
      column :account_id, :uuid, null: false
    end
  end
end
