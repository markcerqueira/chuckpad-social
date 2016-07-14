class AddUserLastLoginAttempt < ActiveRecord::Migration
  def up
    add_column :users, :last_login_attempt, :datetime
  end

  def down
    remove_column :users, :last_login_attempt
  end
end
