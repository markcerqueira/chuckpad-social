class AddLatLngToPatch < ActiveRecord::Migration[5.0]
  # integers suffice for giving a general idea of the location
  def up
      add_column :patches, :lat, :integer, :default => nil
      add_column :patches, :lng, :integer, :default => nil
  end

  def down
    remove_column :patches, :lat, :integer
    remove_column :patches, :lng, :integer
  end
end
