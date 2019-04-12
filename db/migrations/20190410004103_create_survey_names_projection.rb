Sequel.migration do
  up do
    create_table :survey_names_projection do
      column :survey_id, :uuid, null: false
      column :account_id, :uuid, null: false
      column :name, :text, null: false
      column :locale, :text, null: false

      index [:survey_id, :locale]
    end
  end
end
