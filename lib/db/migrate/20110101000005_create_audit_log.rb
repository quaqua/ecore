class CreateAuditLog < ActiveRecord::Migration
  def self.up
    create_table :audit_logs do |t|
      t.references  :user
      t.references  :auditable, :polymorphic => true
      t.string      :node_name
      t.string      :updater_name
      t.string      :action
      t.string      :summary
      t.timestamps
    end
  end

  def self.down
    drop_table :audit_logs
  end
end
