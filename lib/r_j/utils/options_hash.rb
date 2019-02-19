# frozen_string_literal: true

module RJ
  module Utils
    module OptionsHash


      private

      def options_with_symbolized_keys
        recursive_symbolize_keys(options) if options
      end

      def recursive_symbolize_keys(hsh)
        case hsh
        when Hash
          Hash[
            hsh.map do |k, v|
              [k.respond_to?(:to_sym) ? k.to_sym : k, recursive_symbolize_keys(v)]
            end
          ]
        when Enumerable
          hsh.map { |v| recursive_symbolize_keys(v) }
        else
          hsh
        end
      end
    end
  end
end
