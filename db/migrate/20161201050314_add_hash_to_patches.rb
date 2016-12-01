class AddHashToPatches < ActiveRecord::Migration
  def up
    add_column :patches, :data_hash, :string
  end

  def down
    remove_column :patches, :data_hash, :string
  end
end
