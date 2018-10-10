module DryStages
  class Base
    def self.def_stage_def(stage_name, config_prefix, stage_method)
      previous_stage_name = stages.last || :input
      @stages << stage_method.to_sym
      define_singleton_method("def_#{stage_name}_stage") do |name, transform_proc = nil, &transform_block|
        if transform_proc && transform_block
          raise "Proc and block passed to def_#{stage_name}_def. Only one is allowed at a time."
        end
        transform_proc ||= transform_block
        define_method("#{config_prefix}_#{name}") do |*args|
          self.class.send(:define_method, stage_method) do
            cache_stage(stage_method) do
              previous_stage_output = send(previous_stage_name)
              instance_exec(previous_stage_output, *args, &transform_proc)
            end
          end
          self.class.send(:private, stage_method)
          invalidate_from(stage_method)
          self.class.send(:define_method, "#{stage_name}_result") do
            instance_variable_get(cache_variable_name(stage_method))
          end
          self
        end
      end
    end

    def self.stages
      super_stages = superclass.respond_to?(:stages) ? superclass.stages : []
      super_stages + (@stages ||= [])
    end

    def run!
      self.send(self.class.stages.last || :input)
    end

    def input
      raise "subclasses of #{Base.name} must implement #input"
    end

    def stages
      self.class.stages
    end

    private

    # stage caching

    def cache_variable_name(stage_method)
      :"@#{stage_method}_cache"
    end

    def cache_stage(stage_method, &block)
      variable_name = cache_variable_name(stage_method)
      if instance_variable_defined?(variable_name)
        instance_variable_get(variable_name)
      else
        instance_variable_set(cache_variable_name(stage_method), block.call)
      end
    end

    def invalidate_from(stage_method)
      self.
        stages.
        drop_while { |some_stage_method| some_stage_method != stage_method.to_sym }.
        each do |stage_method_to_invalidate|
        variable_name = cache_variable_name(stage_method_to_invalidate)
        if instance_variable_defined?(variable_name)
          remove_instance_variable(variable_name)
        else
          break
        end
      end
    end
  end
end
