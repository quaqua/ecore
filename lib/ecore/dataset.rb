# extends sequel dataset
module Sequel
  class Dataset

    # Setup values for later use with
    # :receive method, so objects can be 
    # initialized and passed back.
    #
    # custom_repository_options can be used to bypass the default's
    # repository access validations (useful for classes like user, groups or informational classes)
    #
    def store_preconditions(user_id,type,parent=nil,custom_repository_options=nil,additional_options={:hidden => false},custom_class=nil)
      @parent = parent
      user_id = user_id.id_and_group_ids if user_id.is_a?(Ecore::User)
      @user_id = user_id
      @custom_repository_class = custom_class
      return filter(custom_repository_options) if @custom_repository_class
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
        if @custom_repository_class
          all.map{ |u| @custom_repository_class.new(@user_id, u) }
        else
          Ecore::DocumentArray.new(@parent, all.map{ |document| get_document(@user_id,document)})
        end
      else
        if @custom_repository_class
          @custom_repository_class.new(@user_id, first)
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
        user_id = user_id.id if user_id.is_a?(Ecore::User)
        type.constantize.new(user_id,document)
      else
        user_id = user_id.id if user_id.is_a?(Ecore::User)
        klass = first_source_table.to_s
        klass.sub!("_trash","") if klass.include?("_trash")
        klass.singularize.classify.constantize.new(user_id,document)
      end
    end

  end
end
