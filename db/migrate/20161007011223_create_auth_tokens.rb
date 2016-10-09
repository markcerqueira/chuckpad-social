class CreateAuthTokens < ActiveRecord::Migration
  def up
    create_table :auth_tokens do |t|
      # id (primary key) from users table
      t.integer :user_id

      # auth token for the user
      t.string :auth_token

      # time token was created
      t.datetime :token_created

      # time token was last used to grant access
      t.datetime :last_access
    end
  end

  def down
    drop_table :auth_tokens
  end
end
