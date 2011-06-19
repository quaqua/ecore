module Ecore
  class AuditLog < ActiveRecord::Base
  
    belongs_to :user
    
    belongs_to :auditable, :polymorphic => true
    
    before_create do
      if user
        self.updater_name = user.name
      end
    end
        
  end
end
