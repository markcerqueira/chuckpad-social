class CreateAbuseReport < ActiveRecord::Migration
  def up
    create_table :abuse_reports do |t|
      t.integer :user_id, :null => false
      t.integer :patch_id, :null => false
      t.datetime :reported_at, :default => Time.now
    end
  end

  def down
    drop_table :abuse_reports
  end
end
