module DryStages
  class Base
    def self.inherited(subclass)
      subclass.define_singleton_method('stages') do
        superclass.stages + (@stages ||= [])
      end
    end

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
              trace "^^^^ run #{stage_name} stage ^^^^"
              trace 'input:'
              trace previous_stage_output.inspect
              trace '*args:'
              trace args.inspect
              instance_exec(previous_stage_output, *args, &transform_proc).tap do |output|
                trace 'output:'
                trace output.inspect
                trace "$$$$$$$$$$$$$$$$$$$$#{stage_name.gsub /./, '$'}"
                puts
              end
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
      @stages ||= []
    end

    def run!
      self.send(self.class.stages.last)
    end

    private

    # stage caching

    def cache_variable_name(stage_method)
      :"@#{stage_method}_cache"
    end

    def cache_stage(stage_method, &block)
      variable_name = cache_variable_name(stage_method)
      if instance_variable_defined?(variable_name)
        trace "cached(#{stage_method})"
        instance_variable_get(variable_name)
      else
        trace "compute(#{stage_method})"
        instance_variable_set(cache_variable_name(stage_method), block.call)
      end
    end

    def invalidate_from(stage_method)
      self.
        class.
          stages.
          drop_while { |some_stage_method| some_stage_method != stage_method.to_sym }.
          each do |stage_method_to_invalidate|
        variable_name = cache_variable_name(stage_method_to_invalidate)
        if instance_variable_defined?(variable_name)
          trace "invalidate(#{stage_method_to_invalidate})"
          remove_instance_variable(variable_name)
        else
          trace "invalidate(#{stage_method_to_invalidate}) failed"
          break
        end
      end
      end

      # debug

      def trace(message)
        if self.class.trace
          puts message
        end
      end

      def self.trace
        true
      end
    end
  end
