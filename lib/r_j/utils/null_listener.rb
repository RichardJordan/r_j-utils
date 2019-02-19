# frozen_string_literal: true

require 'naught'

module RJ
  module Utils
    module NullListener
      attr_writer :null_listener_class


      private

      def null_listener
        _null_listener_source.call
      end

      def _null_listener_class
        @null_listener_class ||= Naught.build
      end

      def _null_listener_source
        _null_listener_class.public_method(:new)
      end
    end
  end
end
