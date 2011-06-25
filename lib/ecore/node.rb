$:.push File.expand_path("../node", __FILE__)

module Ecore

  # Node is the main class of the ecore content repository
  #
  #   Ecore::Node.find(session, type, query)
  #
  # will lookup for nodes fitting the session's user privileges and
  # the given query for nodes of type node
  #
  class Node

    class << self

      @registered_nodes
      
      # registeres a class to be known as an ecore
      # class
      #
      # this enables the opportunity to look up nodes
      # with Ecore::Node.find method
      #
      # ==== Parameters
      #
      # +class_name+ - name of the class to be registered (String)
      def register( class_name )
        @registered_nodes ||= []
        @registered_nodes << class_name unless @registered_nodes.include?( class_name )
      end

      # returns all registered nodes
      def registered
        @registered_nodes ||= []
      end


      # finds all nodes registered with the Ecore::Node.register method
      def find( session, attrs )
        @registered_nodes ||= []
        @registered_nodes.inject(Ecore::NodeArray.new) do |arr, class_name|
          arr += class_name.constantize.find( session, attrs )
        end
      end

      def first( session, attrs )
        @registered_nodes ||= []
        @registered_nodes.each do |class_name|
          if node = class_name.constantize.first(session, attrs)
            return node
          end
        end
      end

    end

    # instance methods

  end
end
