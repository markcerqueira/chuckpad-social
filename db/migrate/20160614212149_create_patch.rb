# Created with the following command:
#  => rake db:create_migration NAME=create_patch
class CreatePatch < ActiveRecord::Migration
  def up
    create_table :patches do |t|
      t.string :name, :null => false
      t.string :description, :null => false

      t.boolean :hidden, :default => false
      t.boolean :featured, :default => false
      t.boolean :documentation, :default => false

      t.integer :creator_id

      t.integer :parent_id, :default => -1

      t.integer :download_count, :default => 0
      t.integer :abuse_count, :default => 0

      t.integer :revision, :default => 0

      t.datetime :created_at
      t.datetime :updated_at

      t.string :filename
      t.binary :data, :null => false
    end
  end

  def down
    drop_table :patches
  end
end