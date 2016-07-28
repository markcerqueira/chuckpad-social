class AddDescriptionAndParentPatchToPatches < ActiveRecord::Migration
  def up
    add_column :patches, :description, :string
    add_column :patches, :parent_id, :integer, :default => -1
  end

  def down
    remove_column :patches, :description
    remove_column :patches, :parent_id
  end
end
