module Ecore
  module Hooks

    module ClassMethods
      def before(action, method_name, options={})
        @hooks ||= {}
        @hooks[:before] ||= {}
        @hooks[:before][:"#{action}"] ||= {}
        @hooks[:before][:"#{action}"][method_name] = options
      end

      def after(action, method_name, options={})
        @hooks ||= {}
        @hooks[:after] ||= {}
        @hooks[:after][:"#{action}"] ||= {}
        @hooks[:after][:"#{action}"][method_name] = options
      end


      def configured_hooks
        hash = {}
        klass = self
        while klass.respond_to?(:before)
          hash = klass.hooks.merge(hash) if klass.hooks
          klass = klass.superclass
        end
        hash
      end
    
      def hooks
        @hooks || {}
      end

    end

    module InstanceMethods

      def run_hooks(action_trigger,action_type)
        conf_hooks = self.class.configured_hooks
        return unless conf_hooks.has_key?(action_trigger.to_sym)
        return unless conf_hooks[action_trigger.to_sym].has_key?(action_type.to_sym)
        conf_hooks[action_trigger.to_sym][action_type.to_sym].each_pair do |hook_method, options|
          Ecore::logger.warn("options not implemented yet") if options.size > 0
          send(hook_method.to_s)
        end
      end

    end

  end
end
