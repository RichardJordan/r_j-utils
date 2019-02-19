# frozen_string_literal: true

require 'r_j/utils'
require_relative '../../../spec_helper_lite'

class TestCommandClass < RJ::Utils::Commands::Base
  def call
    true
  end

  def null_listener
    true
  end

  def default_failure_callback
    true
  end

  def default_success_callback
    true
  end
end

# rubocop:disable RSpec/AnyInstance
module RJ
  module Utils
    module Commands
      RSpec.describe Base do
        context 'provides interface to subclasses' do
          describe 'enforces duct typing' do
            describe '#call' do
              context 'when not implemented' do
                class TestClassNoCall < Base
                  def inputs=
                    true
                  end
                end

                it 'raises NotImplementedError' do
                  expect { TestClassNoCall.allocate.send(:call) }.to raise_error(NotImplementedError)
                end

              end

              context 'when implemented' do
                class TestClassCall < Base
                  def inputs=
                    true
                  end

                  def call
                    true
                  end
                end

                it 'does not raise error' do
                  expect { TestClassCall.allocate.send(:call) }.not_to raise_error
                end

              end
            end

            describe '#default_failure_callback' do
              context 'when not implemented' do
                class TestClassNoDFC < Base
                  def inputs=
                    true
                  end
                end

                it 'raises NotImplementedError' do
                  expect { TestClassNoDFC.allocate.send(:default_failure_callback) }.to raise_error(NotImplementedError)
                end

              end

              context 'when implemented' do
                class TestClassDFC < Base
                  def inputs=
                    true
                  end

                  def default_failure_callback
                    true
                  end
                end

                it 'does not raise error' do
                  expect { TestClassDFC.allocate.send(:default_failure_callback) }.not_to raise_error
                end

              end
            end

            describe '#default_success_callback' do
              context 'when not implemented' do
                class TestClassNoDSC < Base
                  def inputs=
                    true
                  end
                end

                it 'raises NotImplementedError' do
                  expect { TestClassNoDSC.allocate.send(:default_success_callback) }.to raise_error(NotImplementedError)
                end

              end

              context 'when implemented' do
                class TestClassDSC < Base
                  def inputs=
                    true
                  end

                  def default_success_callback
                    true
                  end
                end

                it 'does not raise error' do
                  expect { TestClassDSC.allocate.send(:default_success_callback) }.not_to raise_error
                end

              end
            end
          end

          describe 'allows declaring a command signature' do
            describe 'default_callbacks' do
              class TestCommandClassWithDefaults < Base
                default_callbacks on_success: :testing_on_success, on_failure: :testing_on_failure
              end

              describe 'class methods' do
                describe '.default_callbacks' do

                  it 'takes keyword arguments for on_success, sets callback method names' do
                    expect(TestCommandClassWithDefaults.default_success_callback).to eq(:testing_on_success)
                  end

                  it 'takes keyword arguments for on_failure, sets callback method names' do
                    expect(TestCommandClassWithDefaults.default_failure_callback).to eq(:testing_on_failure)
                  end
                end
              end

              describe 'instance_methods' do

                it 'sets instance#default_failure_callback' do
                  expect(TestCommandClassWithDefaults.allocate.send(:default_failure_callback)).to eq(:testing_on_failure)
                end

                it 'sets instance#default_success_callback' do
                  expect(TestCommandClassWithDefaults.allocate.send(:default_success_callback)).to eq(:testing_on_success)
                end

              end
            end

            describe 'inputs' do
              class TestCommandClassWithDefaults < Base
                required :test_first_input, :test_second_input, :test_second_input
                optional :test_third_input, :test_fourth_input, :test_fourth_input
              end

              describe '.required' do

                it 'takes list of input keys expected' do
                  expect(TestCommandClassWithDefaults.required_inputs.to_a).to eq(%i[test_first_input test_second_input])
                end

                describe 'makes accessors for each' do
                  it { expect { TestCommandClassWithDefaults.allocate.test_first_input }.not_to raise_error }
                  it { expect { TestCommandClassWithDefaults.allocate.test_second_input }.not_to raise_error }
                  it { expect { TestCommandClassWithDefaults.allocate.test_nonsense_input }.to raise_error(NoMethodError) }
                end

              end

              describe '.optional' do

                it 'takes list of input keys expected' do
                  expect(TestCommandClassWithDefaults.optional_inputs.to_a).to eq(%i[test_third_input test_fourth_input])
                end

                describe 'makes accessors for each' do
                  it { expect { TestCommandClassWithDefaults.allocate.test_third_input }.not_to raise_error }
                  it { expect { TestCommandClassWithDefaults.allocate.test_fourth_input }.not_to raise_error }
                  it { expect { TestCommandClassWithDefaults.allocate.test_comedy_input }.to raise_error(NoMethodError) }
                end

              end

              describe 'accessors' do
                class TestCommandClassWithRequired < TestCommandClass
                  required :test_required
                  optional :test_optional
                end

                let(:req) { double }
                let(:opt) { double }
                let(:command_instance) { TestCommandClassWithRequired.new(test_required: req, test_optional: opt) }

                describe '#required_inputs' do

                  it "returns hash of required inputs and values" do
                    expect(command_instance.required_inputs).to eq(test_required: req)
                  end

                end

                describe '#optional_inputs' do

                  it "returns hash of optional inputs and values" do
                    expect(command_instance.optional_inputs).to eq(test_optional: opt)
                  end

                end

                describe '#inputs' do

                  it "returns hash of optional inputs and values" do
                    expect(command_instance.inputs).to eq(test_optional: opt, test_required: req)
                  end

                end
              end
            end
          end

          describe 'building a new command' do
            let(:arguments) { { test: :arg1, test2: :arg2 } }
            let(:command_class) { TestCommandClass }
            let(:command_instance) { instance_spy(command_class) }
            let(:inputs) { { foo: :bar } }

            context 'class methods' do
              before do
                allow(command_class).to receive(:new).and_return(command_instance)
                allow_any_instance_of(command_class).to receive(:inputs=)
              end

              describe '.call' do

                it 'instantiates a new command object and calls it' do
                  command_class.call inputs, **arguments
                  expect(command_instance).to have_received(:call)
                end

              end

              describe '.for' do

                it 'instantiates a new command' do
                  expect(command_class.for).to eq(command_instance)
                end

              end
            end

            describe "initialization" do
              let(:listener) { listener_class.new }
              let(:listener_class) { Class.new }
              let(:on_failure) { -> { :failure } }
              let(:on_success) { -> { :success } }

              it 'takes an optional initial hash of inputs as the first argument e.g. params' do
                expect_any_instance_of(command_class).to receive(:inputs=).with(inputs)
                command_class.new inputs
              end

              context 'takes and sets listener, and on_success, on_failure callbacks' do
                let(:command) { command_class.new listener: listener, on_success: on_success, on_failure: on_failure }

                it "takes and sets a listener" do
                  expect(command.listener).to eq(listener)
                end

                it "takes and sets an on_success callback" do
                  expect(command.on_success).to eq(on_success)
                end

                it "takes and sets an on_failure callback" do
                  expect(command.on_failure).to eq(on_failure)
                end

              end

            end
          end

        end
      end
    end
  end
end
# rubocop:enable RSpec/AnyInstance
