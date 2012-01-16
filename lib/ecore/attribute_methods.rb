module Ecore
  module AttributeMethods

    if RUBY_VERSION.include?("1.8")
      require 'active_support/time'
    end

    attr_accessor :db_setup_attributes

    # Attribute to be defined
    #
    # attributes:
    #  * <tt>name</tt> - attribute name
    #  * <tt>type</tt> - type (see datatypes for a full list)
    #  * <tt>options:</tt> - options compatible with sequel
    def attribute( name, type, options={} )
      @db_setup_attributes ||= {}
      @db_setup_attributes[name.to_sym] = [type, options]
      create_attribute_methods(name, type, options)
    end

    def create_attribute_methods(name, type, options, link=false)
      send(:define_method, :"#{name}=", lambda{ |val|
        if type == :integer || type == Fixnum
          val = val.to_i if val.is_a?(String) && val.match(/^\d+$/)
        elsif type == :float || type == :double || type == Float
          val = val.sub(',','.').to_f if val.is_a?(String) && val.match(/^\d+[\.,\,]{0,1}\d*$/)
          val = val.to_f if val.is_a?(Integer)
        elsif type == :datetime || type == :date || type == Date || type == DateTime
          if val.is_a?(String)
            if val.size > 10
              val = Time.parse(val)
            else
              val = Time.parse("#{val} 00:00:00")
            end
          end
          val = Time.at(val) if val.is_a?(Float)
          val = val.to_date if type == :date && val.is_a?(Time)
        elsif type == :boolean || type == TrueClass
          val = (val.is_a?(TrueClass) || 
                 (val.is_a?(String) && (val == "1" || val.downcase[0,1] == "t")) ||
                 (val.is_a?(Integer) && val == 1)) ? true : false
        end
        if !@orig_attributes || (!@orig_attributes.has_key?(name.to_sym) || @orig_attributes[name.to_sym] != val)
          @changed_attributes ||= {}
          @changed_attributes[name.to_sym] = val
        end
        instance_variable_set("@"+name.to_s,val)
        self.attributes[name.to_sym] = val unless link
      })
      send(:define_method, name.to_sym, lambda{
        instance_variable_get("@"+name.to_s)
      })
      send(:define_method, "#{name}?".to_sym, lambda{
        instance_variable_get("@#{name}")
      }) if type == :boolean
    end
  end
end
