require File::expand_path("../user", __FILE__)

module Ecore
  class Group < Ecore::User

    # Overwrites the Users's find method by adding
    # group condition
    def self.find(user_id_or_user,options={})
      super(user_id_or_user, options.merge(:group => true))
    end

    # Returns the number of groups in the
    # repository
    def self.count
      Ecore::db[:users].filter(:group => true).count
    end

    # Shows the group's members
    # returns an array of Ecore::User of this group
    def users
      r = Ecore::User.find(@user_id, :group_ids.like("%#{@id}%")).receive(:all)
      puts r.inspect
      r
    end


  end
end
