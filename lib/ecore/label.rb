module Ecore
  class Label

    # Creates the label table
    # if not present.
    #
    def self.migrate
      Ecore::db.create_table :labels do
        String  :id, :size => 8, :primary_key => true
        String  :name, :null => false
        String  :color
        index :name
      end unless Ecore::db.table_exists?(:labels)
    end

    # Returns the number of labels
    def self.size
      Ecore::db[:labels].count
    end

    # Finds all labels matchign given option.
    #
    # The returned labels will be ordered by name (by default)
    #
    # example:
    #   Ecore::Label.find(user, :name => 'l1')
    #   # => [<Ecore::Label @name => 'one'>, <Ecore::Label @name => 'two'>]
    #
    #   Ecore::Label.find(user, :name => 'l1', :descending => true)
    #   # => [<Ecore::Label @name => 'two'>, <Ecore::Label @name => 'one'>]
    #
    def self.find(user_id_or_user, options)
      user_id = user_id_or_user.is_a?(String) ? user_id_or_user : user_id_or_user.id
      desc = options.delete(:descending)
      labels = Ecore::db[:labels].filter(options)
      desc ? labels.order(:name.desc) : labels.order(:name)
      labels.all.map do |label|
        new(user_id, label)
      end
    end

    attr_accessor :id, :name, :color
    attr_reader :user_id

    def initialize(user_id, attrs)
      @user_id = user_id
      if attrs.is_a?(Hash) && attrs.keys.size > 0
        attrs.each_pair do |name, val|
          send(:"#{name}=", val)
        end
      end
    end

    # Returns all prepared dataset to look up documents with
    # association to this label
    #
    # examples:
    #   label.documents
    #   # => <Sequel::Dataset where(:label_ids.like(this_label_id))>
    #
    #   label.documents.where(:type => Contact).receive(:all)
    #   # => [<Contact @name => 'c1'>, <Contact @name => 'c2'>]
    #
    def documents
      Ecore::Document.find(@user_id).where(:label_ids.like("%#{self.id}%"))
    end

  end
end
