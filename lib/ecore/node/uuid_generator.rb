require 'uuidtools'

module Ecore
  
  module UUIDGenerator
  
    def setup_uuid
      self.id = UUIDTools::UUID.timestamp_create.to_s
    end
    
  end
  
end
