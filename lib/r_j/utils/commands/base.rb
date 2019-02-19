# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'

require 'r_j/utils/commands/errors'
require 'r_j/utils/commands/notifications'
require 'r_j/utils/null_listener'
require 'r_j/utils/options_hash'

module RJ
  module Utils
    module Commands
      class Base
        include Errors
        include Notifications
        include NullListener
        include OptionsHash

        class << self
          attr_reader :default_failure_callback, :default_success_callback

          def call(inputs={}, **args)
            new(inputs, **args).call
          rescue NoMethodError => e
            raise Errors::InvalidCommandInputs.new "Invalid Input #{e.message[/`(.*?)='/m, 1]}"
          end

          def for(inputs={}, **args)
            new(inputs, **args)
          rescue NoMethodError => e
            raise Errors::InvalidCommandInputs.new "Invalid Input #{e.message[/`(.*?)='/m, 1]}"
          end

          def default_callbacks(**args)
            @default_success_callback = args[:on_success]
            @default_failure_callback = args[:on_failure]
          end

          def optional(*input_names)
            input_names.each do |input_name|
              optional_inputs << input_name
              attr_accessor input_name
            end
          end

          def optional_inputs
            @optional_inputs ||= Set.new
          end

          def required(*input_names)
            input_names.each do |input_name|
              required_inputs << input_name
              attr_accessor input_name
            end
          end

          def required_inputs
            @required_inputs ||= Set.new
          end
        end

        attr_reader :listener, :on_success, :on_failure

        def initialize(inputs={}, listener: nil, on_success: nil, on_failure: nil, **args)
          @listener   = listener   || null_listener
          @on_success = on_success || default_success_callback
          @on_failure = on_failure || default_failure_callback

          self.inputs = recursive_symbolize_keys inputs.merge!(args)

          unless valid_command_inputs?
            raise Errors::InvalidCommandInputs.new(
              "Missing required inputs: '#{missing_command_inputs.join(', ')}'",
            )
          end
        end

        def call
          raise NotImplementedError
        end

        def inputs=(inputs)
          inputs.each { |input, value| public_send("#{input}=", value) }
        end

        def inputs
          required_inputs.merge(optional_inputs)
        end

        def optional_inputs
          self.class.optional_inputs.each_with_object({}) do |input, optional_inputs|
            optional_inputs[input] = public_send(input)
          end
        end

        def required_inputs
          self.class.required_inputs.each_with_object({}) do |input, required_inputs|
            required_inputs[input] = public_send(input)
          end
        end


        private

        def valid_command_inputs?
          self.class.required_inputs.all? { |input| !send(input).nil? }
        end

        def missing_command_inputs
          self.class.required_inputs.select { |input| send(input).nil? }
        end

        # Callbacks

        def failure(*return_args)
          notify_observers of_event: :failure
          listener.public_send(on_failure, *return_args)
        end

        def success(*return_args)
          notify_observers of_event: :success
          listener.public_send(on_success, *return_args)
        end


        # Default Callbacks

        def default_failure_callback
          raise NotImplementedError unless self.class.default_failure_callback

          self.class.default_failure_callback
        end

        def default_success_callback
          raise NotImplementedError unless self.class.default_success_callback

          self.class.default_success_callback
        end

      end
    end
  end
end
