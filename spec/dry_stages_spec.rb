# frozen_string_literal: true

require 'csv'

RSpec.describe DryStages do
  it 'has a version number' do
    expect(DryStages::VERSION).not_to be nil
  end

  let(:export_class) do
    Class.new(DryStages::Base) do
      attr_reader :input
      def initialize
        @input   = [[1, 2, 3], [:a, :b, :c]]
        @next_id = 1
        @store   = {}
      end

      def store(data)
        id         = @next_id
        @next_id  += 1
        @store[id] = data
        id
      end

      def find(id)
        @store[id]
      end

      def_stage_def('format', 'to')
      def_stage_def('persistence', 'persist_with')
      def_stage_def('delivery', 'send_to')

      def_format_stage 'csv', -> (table, **options) {
        CSV.generate(**options) do |csv|
          table.each do |row|
            csv << row
          end
        end
      }

      def_persistence_stage 'store', -> (data) {
        store(data)
      }

      def_delivery_stage 'debug', -> (id) {
        puts
        puts '    ^^^^ DELIVER DEBUG ^^^^'
        puts "    id: #{ id }"
        puts '    #######################'
        puts '    content:'
        puts find(id)
        puts '    $$$$$$$$$$$$$$$$$$$$$$$'
        puts
      }
    end
  end

  it 'does something useful' do
    export = export_class.new
    p export.class.dry_stages
    p export
    export.to_csv.persist_with_store.send_to_debug.run!
    puts
    puts
    export.persist_with_store.run!
    p export
    p export.dry_stage_result :format
    p export.dry_stage_result :persistence
    p export.dry_stage_result :delivery
    export.to_csv(col_sep: ';')
  end

  let(:export_sub_class) do
    Class.new(export_class) do
      def_format_stage 'reverse_csv', -> (table, **options) {
        CSV.generate(**options) do |csv|
          table.each do |row|
            csv << row
          end
        end.reverse
      }
    end
  end

  it 'does not blow up in my face' do
    export = export_sub_class.new
    p export.class.dry_stages
    p export.to_reverse_csv.persist_with_store.send_to_debug
    p export.run!
    p export.dry_stages_configs
  end

  it 'works' do
    c = Class.new do
      include DryStages::Stages

      def_stage_def 'transform', 'to'

      def_transform_stage 'reverse', -> (input) { input.split('').reverse.join }

      def input
        'abc'
      end
    end

    e = c.new.to_reverse
    p e.dry_stages_configs
    p e.run!
    p e.dry_stage_result :transform
  end
end
