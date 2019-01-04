# frozen_string_literal: true

module DryStages
  module Stages

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def def_stage_def(stage_name, config_prefix = nil, configurable: true, &default_transform_proc)
        raise "No default implementation for non configurable stage #{stage_name} given." if !configurable && default_transform_proc.nil?
        raise "Config prefix for non configurable stage #{stage_name} given." if !configurable && !config_prefix.nil?
        raise "Config prefix for configurable stage #{stage_name} missing." if configurable && config_prefix.nil?
        previous_stage_index  = dry_stages.length - 1
        current_stage_index   = previous_stage_index + 1
        stage_def_method_name = :"def_#{stage_name}_stage"

        @_dry_stages << { name: stage_name.to_sym, configurable: configurable, default_transform_proc: default_transform_proc }

        if configurable
          define_singleton_method(stage_def_method_name) do |name, transform_proc = nil, &transform_block|
            if transform_proc && transform_block
              raise "Proc and block passed to #{ stage_def_method_name }. Only one is allowed at a time."
            end

            transform_proc         ||= transform_block
            stage_config_method_name = :"#{config_prefix}_#{name}"

            define_method(stage_config_method_name) do |*args|
              stage_config                             = { stage: stage_name.to_sym, type: name.to_sym, args: args, transform_proc: transform_proc }
              _dry_stages_configs[current_stage_index] = stage_config
              invalidate_from(current_stage_index)
              self
            end
          end
        end
      end

      def dry_stages
        super_stages  = superclass.respond_to?(:dry_stages) ? superclass.dry_stages : []
        @_dry_stages ||= []
        super_stages + @_dry_stages
      end

    end

    # public interface

    def run!
      run_dry_stage!(dry_stages.length - 1)
    end

    def input
      raise "subclasses of #{ Base.name } must implement #input"
    end

    # public introspection methods

    def dry_stages
      self.class.dry_stages.map { |name:, **_| name }
    end

    def dry_stages_configs
      _dry_stages_configs.map { |config| config.slice(:stage, :type, :args) }
    end

    def dry_stage_result(stage_name)
      stage_index = dry_stages.index(stage_name.to_sym)
      if stage_index.nil?
        raise "unknow dry_stage #{ stage_name }. Avalable stages #{ dry_stages }"
      else
        (@_dry_stages_cache ||= []).fetch(stage_index) { raise "uncached dry_stage #{ stage_name }" }
      end
    end

    private

    def _dry_stages_configs
      @_dry_stages_configs ||= self.class.dry_stages.map do |name:, default_transform_proc:, **_|
        if default_transform_proc
          {
            stage: name.to_sym,
            type: :default,
            args: [],
            transform_proc: default_transform_proc
          }
        end
      end
    end

    def dry_stage_config(index)
      _dry_stages_configs[index] || (raise "unconfigured dry_stage #{ dry_stages[index] }")
    end

    def run_dry_stage!(index)
      if index >= 0
        cache_stage(index) do
          previous_stage_index  = index - 1
          previous_stage_output = run_dry_stage!(previous_stage_index)
          stage_config          = dry_stage_config(index)
          transform_proc        = stage_config[:transform_proc]
          args                  = stage_config[:args]
          instance_exec(previous_stage_output, *args, &transform_proc)
        end
      else
        input
      end
    end

    # stage caching

    def cache_stage(index)
      if (@_dry_stages_cache ||= []).length > index
        @_dry_stages_cache[index]
      else
        @_dry_stages_cache[index] = yield
      end
    end

    def invalidate_from(index)
      @_dry_stages_cache = (@_dry_stages_cache || []).take(index)
    end

  end
end
