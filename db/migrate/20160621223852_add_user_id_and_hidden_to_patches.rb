class AddUserIdAndHiddenToPatches < ActiveRecord::Migration
  def up
    add_column :patches, :creator_id, :integer
    add_column :patches, :hidden, :boolean
  end

  def down
    remove_column :patches, :creator_id
    remove_column :patches, :hidden
  end
end
