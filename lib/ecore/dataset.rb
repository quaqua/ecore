# extends sequel dataset
module Sequel
  class Dataset

    # Setup values for later use with
    # :receive method, so objects can be 
    # initialized and passed back.
    #
    # user_options is only used in Ecore::User class
    #
    def store_preconditions(user_id,type,parent=nil,user_options=nil,additional_options={:hidden => false})
      @parent = parent
      @user_id = user_id
      @users = !user_options.nil?
      return filter(user_options) if @users
      stmt = "acl_read LIKE '%#{Ecore::User.anybody_id}%'"
      if user_id.include?(',')
        user_id.split(',').each do |uid|
          stmt << " OR acl_read LIKE '%#{uid}%'"
        end
      else
        stmt << " OR acl_read LIKE '%#{user_id}%'"
      end
      additional_options.delete(:hidden) if additional_options[:hidden] == true
      ds = where(stmt).where(additional_options)
      ds = ds.where(:type => type) if type
      ds
    end

    def receive(all_or_first=:first)
      if all_or_first.to_sym == :all
        if @users
          all.map{ |u| Ecore::User.new(@user_id, u) }
        else
          Ecore::DocumentArray.new(@parent, all.map{ |document| get_document(@user_id,document)})
        end
      else
        if @users
          Ecore::User.new(@user_id, first)
        else
          get_document(@user_id,first)
        end
      end
    end

    private

    def get_document(user_id, document)
      return unless document
      type = document.delete(:type)
      if type && first_source_table == :documents
        type.constantize.find(user_id, :hidden => true).where(:id => document[:id]).receive
      elsif type && first_source_table == :documents_trash
        type.constantize.find(user_id, :trashed => true, :hidden => true).where(:id => document[:id]).receive
      elsif type
        type.constantize.new(user_id,document)
      else
        klass = first_source_table.to_s
        klass.sub!("_trash","") if klass.include?("_trash")
        klass.singularize.classify.constantize.new(user_id,document)
      end
    end

  end
end
