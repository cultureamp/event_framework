Sequel.migration do
  up do
    drop_table :question_command_projection_b
    drop_table :question_command_projection_b_surveys

    from(:bookmarks).where(name: 'Domains::Projectors::QuestionCommandProjectorB').delete
  end
end
