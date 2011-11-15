module Ecore

  # provides Rails active_model compatibility
  module ActiveModelLayer

    # The default string to join composite primary keys with in to_param.
    DEFAULT_TO_PARAM_JOINER = '-'.freeze

    # False if the object is new? or has been destroyed, true otherwise.
    def persisted?
      !new_record? && @destroyed != true
    end

    # An array of primary key values, or nil if the object is not persisted.
    def to_key
      [id]
    end

    # With the ActiveModel plugin, Sequel model objects are already
    # compliant, so this returns self.
    def to_model
      self
    end

    # A string representing the object's primary key.  For composite
    # primary keys, joins them with to_param_joiner.
    def to_param
     to_key.join(DEFAULT_TO_PARAM_JOINER) if persisted? && to_key
    end

    # returns true if record has not been saved yet
    def new_record?
      id.nil?
    end

    private

    # The string to use to join composite primary key param strings.
    def to_param_joiner
      DEFAULT_TO_PARAM_JOINER
    end
  end
end
