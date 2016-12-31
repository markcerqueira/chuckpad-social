class CreatePasswordResetToken < ActiveRecord::Migration[5.0]
  def up
    create_table :password_reset_tokens do |t|
      # id (primary key) from users table
      t.integer :user_id

      # randomly generated string token
      t.string :reset_token

      # time this token will expire
      t.datetime :expire_time
    end
  end

  def down
    drop_table :password_reset_tokens
  end
end
