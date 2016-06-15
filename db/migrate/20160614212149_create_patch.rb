# Created with the following command:
# => rake db:create_migration NAME=create_model
class CreatePatch < ActiveRecord::Migration
  def up
    create_table :patches do |t|
      t.string :name, :null => false
      t.boolean :featured
      t.boolean :documentation
      t.binary :data, :null => false
    end
  end

  def down
    drop_table :patches
  end
end
