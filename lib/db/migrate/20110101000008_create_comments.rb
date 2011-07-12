class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.string      :user_id, :limit => 36
      t.string      :node_id, :limit => 36
      t.string      :node_type
      t.text      :body_text
      t.timestamps
    end
    add_index :comments, :user_id
    add_index :comments, :node_id
  end

  def self.down
    drop_table :comments
    remove_index :comments, :user_id
    remove_index :comments, :node_id
  end
end
