module Ecore
  class NodeArray < Array

    def order( order_attrs )
      new_order = self.class.new
      order_attrs.split(',').each do |a|
        clean_a = a.sub(' DESC','').sub(' ASC','')
        next unless self.first.respond_to?(clean_a)
        self.each do |node|
          tmp_order = self.class.new(new_order)
          ( new_order << node ; next ) if node == self.first
          new_order.each_with_index do |n,i|
            evalstr = "node.#{clean_a} && n.#{clean_a} && node.#{clean_a} < n.#{clean_a}"
            evalstr = "node.#{clean_a} && n.#{clean_a} && node.#{clean_a}.downcase < n.#{clean_a}.downcase" if node.send(clean_a).is_a?(String)
            if eval(evalstr)
              tmp_order.insert(i,node)
              break
            elsif tmp_order.size-1 == i
              tmp_order << node
              break
            end
          end
          new_order = self.class.new(tmp_order)
        end
        new_order.reverse! if a.include?(' DESC')
      end
      new_order
    end

    # looks up an attribute in the current array (mostly makes just
    # sense, if cached.
    # e.g.:
    # nodes.find(:id => 'we236oi2')
    def find(attrs)
      res = self.inject(self.class.new) do |arr, node|
        hits = nil
        attrs.each_pair do |k,v|
          if node.respond_to?(k) and eval("node.#{k}") == v
            hits = true if hits.nil?
          else
            hits = false
          end
        end
        arr << node if hits
        arr
      end
      (res.size == 1 && attrs.has_key?(:id)) ? res.first : res
    end

    def to_hash
      self.inject(Array.new) { |array, n| array << n.to_hash ; array }
    end

  end
end
