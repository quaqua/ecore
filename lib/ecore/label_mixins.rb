module Ecore
  module LabelMixins

    # Returns the labels in an Array
    #
    #   document.labels
    #   # => [<Ecore::Label @name => 'label1'>, <Ecore::Label @name => 'label2'>]
    #
    def labels
      return @labels_cache if @labels_cache
      ls = self.label_ids.split(',').map do |label_id|
        Ecore::Label.new(@user_id, Ecore::db[:labels].first(:id => label_id))
      end
      @labels_cache = ls
    end

    # Adds and creates (if it doesn't exist) a label
    # with given name to this document.
    #
    # The document will not be saved with this method.
    #
    # examples:
    #   document.add_label(:name => "label name")
    #
    def add_label(options)
      return false unless options.is_a?(Hash)
      return false unless options.has_key?(:name)
      label = Ecore::db[:labels].first(:name => options[:name])
      unless label
        Ecore::db[:labels].insert(:name => options[:name], :id => gen_unique_id(:labels))
        label = Ecore::db[:labels].first(:name => options[:name])
      end
      labelarr = self.label_ids.split(',')
      labelarr << label[:id]
      self.label_ids = labelarr.join(',')
      @labels_cache = nil
      true
    end

    # Removes a label from a document
    #
    def remove_label(options)
      return false unless options.is_a?(Hash)
      label_id = nil
      if options[:name]
        label = Ecore::db[:labels].first(:name => options[:name])
        label_id = label[:id]
      elsif options[:id]
        label_id = options[:id]
      end
      labelarr = self.label_ids.split(',')
      labelarr.delete(label_id)
      self.label_ids = labelarr.join(',')
      @labels_cache = nil
      true
    end

    private

    include Ecore::UniqueIDGenerator

  end
end
