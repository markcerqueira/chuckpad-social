# Created with the following command:
#  => rake db:create_migration NAME=create_patch
class CreatePatch < ActiveRecord::Migration[5.0]
  def up
    create_table :patches do |t|
      # We want to avoid externally exposing the id because those are sequential so think of GUID as the external
      # id clients can use to find a patch
      t.string :guid

      t.string :name, :null => false
      t.string :description, :null => false

      # Different clients (e.g. MiniAudicle, Auraglyph) use this service so differentiate the patches
      # Mapping of client to integer is in the model class patch.rb
      t.integer :patch_type

      t.boolean :hidden, :default => false
      t.boolean :featured, :default => false
      t.boolean :documentation, :default => false

      t.integer :creator_id

      t.string :parent_guid, :default => nil

      t.integer :download_count, :default => 0
      t.integer :abuse_count, :default => 0

      t.integer :revision, :default => 0

      t.datetime :created_at
      t.datetime :updated_at

      # The SHA256 digest for the most recent uploaded resource. This is used to avoid a user uploading the same exact
      # patch data over and over again.
      t.string :data_hash

      # extra_data represents arbitrary meta-data associated with the patch (e.g. Auraglyph image "name")
      t.binary :extra_data

      # If a patch is deleted we flag it as deleted and never return it from any API calls
      t.boolean :deleted, :default => false
    end
  end

  def down
    drop_table :patches
  end
end