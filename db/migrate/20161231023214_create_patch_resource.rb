class CreatePatchResource < ActiveRecord::Migration[5.0]
  def up
    create_table :patch_resources do |t|
      # GUID for the owning patch
      t.string :patch_guid

      # This will increment as we create more entries for a particular GUID
      t.integer :version

      t.binary :data, :null => false

      t.datetime :created_at
    end
  end

  def down
    drop_table :patch_resources
  end
end
