module Ecore
  module AttributeMethods

    attr_accessor :db_setup_attributes

    def attribute( name, type, options={} )
      @db_setup_attributes ||= {}
      @db_setup_attributes[name.to_sym] = [type, options]
      create_attribute_methods(name, type, options)
    end

    def create_attribute_methods(name, type, options, link=false)
      send(:define_method, :"#{name}=", lambda{ |val|
        if type == :integer
          val = val.to_i if val.is_a?(String) && val.match(/^\d+$/)
        elsif type == :float || type == :double
          val = val.sub(',','.').to_f if val.is_a?(String) && val.match(/^\d+[\.,\,]{0,1}\d*$/)
          val = val.to_f if val.is_a?(Integer)
        elsif type == :datetime || type == :date
          if val.is_a?(String)
            if val.size > 10
              val = Time.parse(val)
            else
              val = Time.parse("#{val} 00:00:00")
            end
          end
          val = Time.at(val) if val.is_a?(Float)
          val = val.to_date if type == :date
        elsif type == :boolean
          val = (val.is_a?(TrueClass) || 
                 (val.is_a?(String) && (val == "1" || val.downcase[0..1] == "t")) ||
                 (val.is_a?(Integer) && val == 1)) ? true : false
        end
        instance_variable_set("@"+name.to_s,val)
        @changed_attributes ||= {}
        @changed_attributes[name.to_sym] = val
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
