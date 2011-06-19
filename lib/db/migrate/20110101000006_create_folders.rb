class CreateFolders < ActiveRecord::Migration
  def self.up
    create_table :folders, :id => false do |t|
      t.ecore_node
      
      t.string    :default_controller
      t.string    :color
    end
    add_index :folders, :name
  end

  def self.down
    drop_table :folders
    remove_index :folders, :name
  end
end
