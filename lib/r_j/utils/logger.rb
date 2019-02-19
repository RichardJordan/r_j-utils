# frozen_string_literal: true

require 'logger'
require 'singleton'

module RJ
  module Utils
    class Logger < ::Logger
      include Singleton

      class << self
        def logger
          @logger ||=
            if defined?(Rails)
              if !Rails.env.production? && Rails.logger
                Rails.logger
              else
                ::Logger.new('/dev/null')
              end
            else
              RJ::Utils::Logger.instance
            end
        end
      end

      def initialize
        super(File.open('log/test.log', 'a'))
      end
    end
  end
end
