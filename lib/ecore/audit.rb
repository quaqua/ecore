module Ecore
  class Audit

    # Creates the audit table
    # if not present.
    #
    def self.migrate
      Ecore::db.create_table :audits do
        column  :id, :string
        column  :name, :string, :null => false
        column  :created_at, :datetime, :null => false
        column  :type, :string, :null => false
        column  :user_id, :string, :null => false
        column  :message, :string
        column  :action, :string, :null => false
        index   :created_at
        index   :id
      end unless Ecore::db.table_exists?(:audits)
    end

    # Logs an event to the repository and to a
    # specified (ecore.yml) audit.log file.
    #
    # * <tt>id</tt> - the id of the object to be logged about
    # * <tt>type</tt> - the type of the object which is logged
    # * <tt>name</tt> - the object's name
    # * <tt>action</tt> - create/update/delete/share/unshare/...
    # * <tt>user_id</tt> - the id of the user who kicked that event
    # * <tt>message</tt> - an additional message
    def self.log(id, type, name, action, user_id, message=nil)
      Ecore::db[:audits].insert(:id => id,
                                :type => type,
                                :name => name,
                                :action => action,
                                :user_id => user_id,
                                :created_at => Time.now,
                                :message => message)
      File.open((Ecore::env.get(:audit_logfile) || 'audit.log'),'a'){ |f| f.write("#{Time.now.strftime('%Y-%m-%d %H:%M:%s')} - ID:#{id}, TYPE:#{type}, NAME:#{name}, ACTION:#{action}, USER_ID:#{user_id}, MESSAGE:#{message}\n") }
    end
  end

end