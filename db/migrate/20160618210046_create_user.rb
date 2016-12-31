# Created with the following command:
#  => rake db:create_migration NAME=create_user
class CreateUser < ActiveRecord::Migration[5.0]
  def up
    create_table :users do |t|
      t.string :username, :null => false
      t.string :email, :null => false
      t.string :salt, :null => false
      t.string :password_hash, :null => false

      t.boolean :email_confirmed, :default => false
      t.string :confirm_token

      t.boolean :admin, :default => false

      t.datetime :last_login_attempt

      t.datetime :created_at
    end
  end

  def down
    drop_table :users
  end
end
