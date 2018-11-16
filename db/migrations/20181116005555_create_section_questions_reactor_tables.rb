Sequel.migration do
  change do
    create_table :section_questions_sections do
      column :section_id, :uuid, null: false, unique: true
      column :status, :text, null: false
    end

    create_table :section_questions_questions do
      column :question_id, :uuid, null: false, unique: true
      column :section_id, :uuid
      column :status, :text, null: false

      index :section_id
    end
  end
end
