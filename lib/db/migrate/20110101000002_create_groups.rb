class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups, :id => false do |t|
      t.string      :id, :primary => true, :limit => 36
      t.string      :name
      t.timestamps
    end
    
  end

  def self.down
    drop_table :groups
  end
  
end
