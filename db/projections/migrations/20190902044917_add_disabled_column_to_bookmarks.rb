Sequel.migration do
  up do
    add_column :bookmarks, :disabled, :bool, null: false, default: true
    from(:bookmarks).update(disabled: false)
  end
end
