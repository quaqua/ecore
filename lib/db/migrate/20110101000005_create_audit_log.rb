class CreateAuditLog < ActiveRecord::Migration
  def self.up
    create_table :audit_logs do |t|
      t.string      :user_id, :limit => 36
      t.string      :node_id, :limit => 36
      t.string      :node_type
      t.string      :action
      t.string      :summary
      t.text        :hashed_acl
      t.timestamps
    end
  end

  def self.down
    drop_table :audit_logs
  end
end
