Sequel.migration do
  up do
    create_table :question_codes_command_projection do
      column :code, :text, primary_key: true
    end
  end
end
