# frozen_string_literal: true

require 'active_support/concern'

module RJ
  module Utils
    module Commands
      module Notifications
        extend ActiveSupport::Concern

        module ClassMethods
          def observer(*observer_methods, of_event: :success)
            observer_methods.each do |observer|
              observers[of_event] ||= Set.new
              observers[of_event] << observer
            end
          end

          def observers
            @observers ||= {}
          end
        end

        def notify_observers(of_event: :success)
          observers_array.each { |observer| safe_call observer }

        rescue StandardError => e
          logger.warn "#{self.class} observers failed with #{e.message}"
          logger.debug e.backtrace.join("\n")
        end

        def observers
          @observers ||=
            self.class.observers.each_with_object({}) do |(event, observer_methods), observers|
              observer_methods.each do |meth|
                observers[event] ||= Set.new
                observers[event] << send(meth)
              end
            end
        end


        private

        def logger
          RJ::Utils::Logger.logger
        end

        def observers_array(of_event: :success)
          Array(observers[of_event]).compact
        end

        def safe_call(observer)
          if observer.respond_to?(:call)
            observer.call
          else
            send observer
          end
        end
      end
    end
  end
end
