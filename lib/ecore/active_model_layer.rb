require 'active_model'
module Ecore

  # provides Rails active_model compatibility
  module ActiveModelLayer
    module ClassMethods
      include ::ActiveModel::Naming

      # Class level cache for to_partial_path.
      def _to_partial_path
        @_to_partial_path ||= "#{name.underscore.pluralize}/#{name.demodulize.underscore}".freeze
      end
    end

    module InstanceMethods
      # The default string to join composite primary keys with in to_param.
      DEFAULT_TO_PARAM_JOINER = '-'.freeze

      # Record that an object was destroyed, for later use by
      # destroyed?
      def after_destroy
        super
        @destroyed = true
      end

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

      # returns true if record has not been saved yet
      def new_record?
        id.nil?
      end

      # An string representing the object's primary key.  For composite
      # primary keys, joins them with to_param_joiner.
      def to_param
        if persisted? and k = to_key
          k.join(to_param_joiner)
        end
      end

      # Returns a string identifying the path associated with the object.
      def to_partial_path
        self.class._to_partial_path
      end

      def model
        to_model
      end

      private

      # The string to use to join composite primary key param strings.
      def to_param_joiner
        DEFAULT_TO_PARAM_JOINER
      end
    end
  end
end
