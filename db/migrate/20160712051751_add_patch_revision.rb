class AddPatchRevision < ActiveRecord::Migration
  def up
    add_column :patches, :revision, :integer, :default => 0
  end

  def down
    remove_column :patches, :revision
  end
end
