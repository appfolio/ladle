class AssociateRepositoryToPullRequest < ActiveRecord::Migration
  def up
    add_column :pull_requests, :repository_id, :integer, null: false

    execute <<-SQL
      UPDATE pull_requests
        SET repository_id = repositories.id
      FROM  repositories
      WHERE repositories.name = pull_requests.repo
    SQL

    remove_column :pull_requests, :repo

    add_foreign_key :pull_requests, :repositories
  end

  def down
    add_column :pull_requests, :repo, :string, null: false

    execute <<-SQL
      UPDATE pull_requests
        SET repo = repositories.name
      FROM  repositories
      WHERE repositories.id = pull_requests.repository_id
    SQL

    remove_foreign_key :pull_requests, :repositories

    remove_column :pull_requests, :repository_id
  end
end
