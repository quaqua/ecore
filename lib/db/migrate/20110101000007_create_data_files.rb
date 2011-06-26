class CreateDataFiles < ActiveRecord::Migration
  def self.up
    create_table :data_files, :id => false do |t|
      t.ecore_node
      t.integer     :file_size
      t.string      :content_type
      t.string      :title
      t.string      :copyright
      t.text        :description
    end
    add_index :data_files, :name
  end

  def self.down
    drop_table :data_files
    remove_index :data_files, :name
  end
end
