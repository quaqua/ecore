class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users, :id => false do |t|
      t.string      :id, :primary => true, :limit => 36
      t.string      :email
      t.string      :hashed_password
      t.string      :name
      t.string      :fullname
      t.string      :group_ids, :default => ""
      t.string      :role, :default => 'user'
      t.boolean     :suspended, :default => false
      t.datetime    :last_login_at
      t.datetime    :last_request_at
      t.string      :last_login_ip
      t.string      :confirmation_key
      t.string      :default_locale, :default => 'en'
      t.timestamps
    end
    add_index :users, :email
  end

  def self.down
    drop_table :users
    remove_index :users, :email
  end
end
