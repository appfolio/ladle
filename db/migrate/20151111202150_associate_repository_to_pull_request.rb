class AssociateRepositoryToPullRequest < ActiveRecord::Migration[4.2]
  def up
    add_column :pull_requests, :repository_id, :integer

    execute <<-SQL
      UPDATE pull_requests
        SET repository_id = repositories.id
      FROM  repositories
      WHERE repositories.name = pull_requests.repo
    SQL

    remove_column :pull_requests, :repo

    change_column_null :pull_requests, :repository_id, false

    add_foreign_key :pull_requests, :repositories
  end

  def down
    add_column :pull_requests, :repo, :string

    execute <<-SQL
      UPDATE pull_requests
        SET repo = repositories.name
      FROM  repositories
      WHERE repositories.id = pull_requests.repository_id
    SQL

    remove_foreign_key :pull_requests, :repositories

    remove_column :pull_requests, :repository_id

    change_column_null :pull_requests, :repo, false
  end
end
