Sequel.migration do
  up do
    from(:bookmarks).where(name: 'Domains::Projectors::QuestionCommandProjector').delete
  end
end
