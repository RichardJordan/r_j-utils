# frozen_string_literal: true

require 'active_model'
require 'virtus'

# require_relative 'form_errors'

module RJ
  module Utils
    module Forms
      class Base
        include Virtus.model

        extend ActiveModel::Naming
        include ActiveModel::Model
        include ActiveModel::Validations

        attr_reader :saved

        def attributes=(attrs)
          set_attrs self, attrs
        end

        def new_record?
          !saved
        end

        def persist!
          raise NotImplementedError
        end

        def persisted?
          false
        end

        def save!
          if valid?
            persist!
            true
          else
            false
          end
        end


        private

        def add_form_errors_for(model:, error_key: nil)
          return if model.valid?

          error_key = model.class.to_s.underscore.to_sym if error_key.nil?
          model.errors.each do |key, message|
            errors.add(error_key, "#{key}: #{message}")
          end
        end

        def set_attrs(object, attrs)
          attrs.each { |k, v| object.send("#{k}=", v) }
        end

      end
    end
  end
end


