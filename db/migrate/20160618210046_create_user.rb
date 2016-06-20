# Created with the following command:
#  => rake db:create_migration NAME=create_user
class CreateUser < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string :username, :null => false
      t.string :email, :null => false
      t.string :salt, :null => false
      t.string :password_hash, :null => false

      t.boolean :admin

    end
  end

  def down
    drop_table :users
  end
end
