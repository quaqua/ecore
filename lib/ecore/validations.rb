module Ecore
  module Validations
  
    module ClassMethods
    
      attr_reader :validations
      
      # validate attribute for specific properties. if type was
      # set with option(:nil => false), a validate :presence, :fieldname
      # has been setup automatically
      # 
      # e.g.:
      #   validate :presence, :firstname
      #
      # Also, custom validations can be defined by providing the method's
      # name. You can access the @errors hash directly. The return state
      # of the custom method defines, if the validation and update process
      # will resume or fail
      #
      # e.g.:
      #   validate :my_custom_validation
      #
      #   private
      #
      #   def my_custom_validation
      #     @errors[:theta] = ['must be greater 10']
      #     false
      #   end
      def validate( type=nil, name=nil, &block )
        @validations ||= []
        if type and name
          case type
          when :presence || :required
            @validations.push(Proc.new{ 
              if send(:"#{name}").nil? or ( send(:"#{name}").is_a?(String) and send(:"#{name}").empty?)
                @errors["#{name}".to_sym] = ["required"]
                false
              else
                true
              end
            })
          when :email_format
            @validations.push(Proc.new{ 
              if send(:"#{name}") && send(:"#{name}").size > 0 && send(:"#{name}").match(/^([^\s]+)((?:[-a-z0-9]\.)[a-z]{2,})$/i).nil?
                @errors["#{name}".to_sym] = ["not a valid email address"]
                false
              else
                true
              end
            })
          when :uniqueness
            @validations.push(Proc.new{
              if (send(:"#{name}").nil? or send(:"#{name}").empty?)
                true
              else
                if record = Ecore::db[self.class.tablename.to_sym][name.to_sym => send(:"#{name}")]
                  if record[:id] != @id
                    @errors["#{name}".to_sym] = [("duplicate entry %s" % send(:"#{name}"))]
                    false
                  else
                    true
                  end
                else
                  true
                end
              end
            })
          end
        elsif type && name.nil? # assuming type == method
          @validations.push(type)
        else # assuming block given
          @validations.push(lambda &block)
        end
      end
      
      def validation_attrs
        attrs = []
        klass = self
        while klass.respond_to?(:validate)
          attrs = klass.validations + attrs if klass.validations
          klass = klass.superclass
        end
        attrs
      end
      
    end
    
    module InstanceMethods
    
      # perform all queued validations
      def run_validations
        run_hooks(:before,:validation)
        @errors ||= {}
        self.class.validation_attrs.each do |validation|
          if validation.is_a?(String) || validation.is_a?(Symbol)
            return false unless send(validation.to_s)
          else
            return false unless instance_eval(&validation)
          end
        end
        true
      end
      
      def errors
        @errors || {}
      end
      
    end

  end
end
