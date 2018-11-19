Sequel.migration do
  change do
    create_table :section_questions_questions do
      column :question_id, :uuid, null: false, unique: true
      column :section_id, :uuid
      column :status, :text, null: false

      index :section_id
    end

    create_table :section_questions_correlation_ids do
      column :event_id, :uuid, null: false, unique: true
      column :correlation_id, :uuid, null: false, unique: true
    end
  end
end
