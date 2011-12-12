module Ecore
  module CustomTransactions
  
    module ClassMethods
    
      attr_reader :custom_transactions
      
      # Adds an additional transaction either before
      # the create/save method is invoked or after
      #
      # e.g.:
      #   transaction :append, :my_custom_transaction
      #
      #   private
      #
      #   def my_custom_transaction
      #     children.create(Folder, :name => 'folder')
      #   end
      def transaction( type, name=nil, &block )
        @custom_transactions ||= []
        if name # assuming name == method
          @custom_transactions.push(name)
        else # assuming block given
          @custom_transactions.push(lambda &block)
        end
      end
      
      # get all defined transactions (from parent classes)
      def transaction_attrs
        attrs = []
        klass = self
        while klass.respond_to?(:transaction)
          attrs = klass.custom_transactions + attrs if klass.custom_transactions
          klass = klass.superclass
        end
        attrs
      end
      
    end
    
    module InstanceMethods
    
      # perform all queued transactions
      def run_custom_transactions(type)
        @errors ||= {}
        self.class.transaction_attrs.each do |custom_transaction|
          if custom_transaction.is_a?(String) || custom_transaction.is_a?(Symbol)
            return false unless send(custom_transaction.to_s)
          else
            return false unless instance_eval(&custom_transaction)
          end
        end
        true
      end
      
    end

  end
end
