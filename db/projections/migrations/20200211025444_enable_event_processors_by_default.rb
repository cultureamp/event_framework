Sequel.migration do
  up do
    alter_table :bookmarks do
      set_column_default :disabled, false
    end
  end
end
