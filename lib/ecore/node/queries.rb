module Ecore
  module Queries

    # finds a node and returns only one node (overwrites AR's first method)
    def first(session, attrs)
      node = where(attrs).where(acl_conditions(session)).limit(1).first
      if node
        node.session = session
        return node if node.can_read?
      end
    end

    # finds a node (overwrites AR find method)
    def find(session, attrs={})
      order,limit,result = 'name',100,nil
      if attrs.is_a?(Hash)
        order = attrs.delete(:order) if attrs.has_key?(:order)
        limit = attrs.delete(:limit) if attrs.has_key?(:limit)
        attrs = attrs[:conditions] if attrs.has_key?(:conditions)
      end
      unless attrs == :all or attrs == {}
        result = where(attrs)
      end
      result.where(acl_conditions(session)).order(order).limit(limit).all.inject(Ecore::NodeArray.new) do |arr, node|
        if node
          node.session = session
          arr << node
        end
        arr
      end
    end

    private

    def acl_conditions(session)
      acl_cond = "hashed_acl LIKE '%#{session.user.id}%'"
      session.user.groups.each do |group|
        acl_cond << " OR hashed_acl LIKE '%#{group.id}%'"
      end
      acl_cond << " OR hashed_acl LIKE '%#{Ecore::User.anybody.id}%' OR hashed_acl LIKE '%#{Ecore::User.everybody.id}%'"
    end

  end

end
