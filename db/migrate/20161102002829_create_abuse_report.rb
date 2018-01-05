class CreateAbuseReport < ActiveRecord::Migration[5.0]
  def up
    create_table :abuse_reports do |t|
      t.integer :user_id, :null => false
      t.integer :patch_id, :null => false
      t.datetime :reported_at
    end
  end

  def down
    drop_table :abuse_reports
  end
end
