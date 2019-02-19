require 'spec_helper_lite'
require 'r_j/utils/commands/notifications'

class TestCommandNotificationsClass
  include RJ::Utils::Commands::Notifications
end

module RJ
  module Utils
    module Commands
      describe Notifications do
        class TestObserverClassMethod < TestCommandNotificationsClass
          observer :test_observer_method, of_event: :success
        end

        let(:observable_class) { TestObserverClassMethod }
        let(:test_instance)    { observable_class.new }
        let(:observer)         { spy(:foo, call: :bar) }

        before do
          test_observer = observer
          observable_class.send(:define_method, :test_observer_method, proc { test_observer })
        end

        after do
          observable_class.send(:undef_method, :test_observer_method)
        end

        describe '.observer' do
          it 'sets an observer method to be called on notify_observers' do
            expect(observable_class.observers[:success].to_a).to eq([:test_observer_method])
          end
        end
        describe '#observers' do
          it 'returns the observers as a hash keyed on event' do
            expect(test_instance.observers[:success]).to satisfy do |result|
              result.first.call == :bar
            end
          end
        end
        describe '#notify_observers' do
          before do
            test_instance.notify_observers of_event: :success
          end

          it "sends messsage :call to the observers" do
            expect(observer).to have_received(:call)
          end
        end
      end
    end
  end
end
