# frozen_string_literal: true

ENV["RAILS_ENV"] ||= 'test'

require 'pry'

RSpec.configure do |config|
  config.filter_run focus: true

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = 'random'
  config.run_all_when_everything_filtered = true
end
