# frozen_string_literal: true

RSpec.describe DryStages do
  it 'has a version number' do
    expect(DryStages::VERSION).not_to be nil
  end

  context 'with a class using DryStages::Stages' do
    let(:example_class) do
      Class.new do
        include DryStages::Stages
      end
    end

    it 'returns dry_stages' do
      expect(example_class.dry_stages).to eq([])
    end

    it 'can define new stages with .def_stage_def' do
      expect(example_class).not_to respond_to(:def_dummy_stage)

      example_class.def_stage_def :dummy, :some_prefix

      expect(example_class).to respond_to(:def_dummy_stage)
    end

    context 'with default stage implementation' do
      let(:example_instance) { example_class.new }

      before do
        example_class.define_method(:input) { 'abc' }
      end

      context 'when not configurable' do
        before do
          example_class.def_stage_def(:format, configurable: false) do |input|
            input.upcase
          end
        end

        it 'uses the default implementation' do
          expect(example_instance.run!).to eq('ABC')
        end

        it 'can not define new transforms' do
          expect(example_class).not_to respond_to(:def_format_stage)
        end
      end

      context 'when configurable' do
        before do
          example_class.def_stage_def(:format, :to, configurable: true) do |input|
            input.upcase
          end
        end

        it 'uses the default implementation' do
          expect(example_instance.run!).to eq('ABC')
        end

        it 'can define new transforms' do
          expect(example_class).to respond_to(:def_format_stage)
        end

        it 'can use non default transforms' do
          example_class.def_format_stage(:hello) { |input| 'hello' }
          expect(example_instance.to_hello.run!).to eq('hello')
        end
      end

    end

    context 'with an instance' do
      before do
        example_class.def_stage_def :format, :to
      end

      let(:example_instance) { example_class.new }

      it 'can define stage implementations' do
        expect(example_instance).
          not_to respond_to(:to_upper_case)

        example_class.def_format_stage :upper_case, -> (input) { input.upcase }

        expect(example_instance).
          to respond_to(:to_upper_case)
      end

      context 'with #input defined' do
        before do
          example_class.define_method(:input) { 'abc' }
          example_class.def_format_stage :upper_case, -> (input) { input.upcase }
        end

        context 'without stage unconfigured' do
          it 'tells the developer about unconfigured stage' do
            expect { example_instance.run! }.to raise_error(/unconfigured/)
          end
        end

        context 'with stage configured' do
          it 'can be run!' do
            expect(example_instance.to_upper_case.run!).to eq('ABC')
          end

          context 'after it has been run' do
            before do
              example_instance.to_upper_case.run!
            end

            it 'can inspect stage result by stage name' do
              expect(example_instance.dry_stage_result(:format)).to eq('ABC')
            end

            context 'and then reconfigured' do
              before do
                example_instance.to_upper_case
              end

              it 'can not inspect stage result by stage name and informs the developer about uncached stage' do
                expect { example_instance.dry_stage_result(:format) }.to raise_error(/uncached/)
              end
            end
          end

          context 'before it has been run' do
            it 'can not inspect stage result by stage name and informs the developer about uncached stage' do
              expect { example_instance.dry_stage_result(:format) }.to raise_error(/uncached/)
            end
          end
        end
      end
    end
  end
end
