module Ecore
  class Audit

    # Creates the audit table
    # if not present.
    #
    def self.migrate
      Ecore::db.create_table :audits do
        String  :id
        String  :name, :null => false
        DateTime :created_at, :null => false
        String  :type, :null => false
        String  :user_id, :null => false
        String  :message
        String  :action, :null => false
        String  :path
        index   :created_at
        index   :path
        index   :id
      end unless Ecore::db.table_exists?(:audits)
    end

    # Logs an event to the repository and to a
    # specified (ecore.yml) audit.log file.
    #
    # * <tt>id</tt> - the id of the object to be logged about
    # * <tt>type</tt> - the type of the object which is logged
    # * <tt>path</tt> - the path of the object which is logged
    # * <tt>name</tt> - the object's name
    # * <tt>action</tt> - create/update/delete/share/unshare/...
    # * <tt>user_id</tt> - the id of the user who kicked that event
    # * <tt>message</tt> - an additional message
    def self.log(id, type, path, name, action, user_id, message=nil)
      Ecore::db[:audits].insert(:id => id,
                                :type => type,
                                :name => name,
                                :action => action,
                                :path => path,
                                :user_id => user_id,
                                :created_at => Time.now,
                                :message => (message.size > 255 ? message[0..255] : message))
      File.open((Ecore::env.get(:audit_logfile) || 'audit.log'),'a'){ |f| f.write("#{Time.now.strftime('%Y-%m-%d %H:%M:%s')} - ID:#{id}, TYPE:#{type}, NAME:#{name}, ACTION:#{action}, USER_ID:#{user_id}, MESSAGE:#{message}\n") }
    end
  end

end
