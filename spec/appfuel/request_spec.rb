module Appfuel
  RSpec.describe Request do
    context '#initialize' do
      context 'initiailize with action route' do
        it 'assigns the action route' do
          request = create_request('foo/bar', {})
          expect(request.action_route).to eq 'foo/bar'
        end

        it 'parses a feature from the route into a container key' do
          request = create_request('foo/bar', {})
          expect(request.feature).to eq 'foo'
        end

        it 'parse a feature with underscores into a container key' do
          request = create_request('foo_doo/bar', {})
          expect(request.feature).to eq 'foo_doo'
        end

        it 'parses an action from the route into a container key' do
          request = create_request('foo/bar', {})
          expect(request.action).to eq 'bar'
        end

        it 'parse an action with underscores into a container key' do
          request = create_request('foo/bar_dar', {})
          expect(request.action).to eq 'bar_dar'
        end

        it 'fails when the route is nil' do
          msg = 'feature is missing, action route must be like <feature/action>'
          expect {
            create_request(nil, {})
          }.to raise_error(RuntimeError, msg)
        end

        it 'fails when the route a feature with no action' do
          msg = 'action is missing, action route must be like <feature/action>'
          expect {
            create_request('foo', {})
          }.to raise_error(RuntimeError, msg)
        end

        it 'fails when the route a feature with no action feature has a slash' do
          msg = 'action is missing, action route must be like <feature/action>'
          expect {
            create_request('foo/', {})
          }.to raise_error(RuntimeError, msg)
        end


        it 'fails when the route a feature and action are missing' do
          msg = 'feature is missing, action route must be like <feature/action>'
          expect {
            create_request('/', {})
          }.to raise_error(RuntimeError, msg)
        end

        it 'fails when foward slash is padded with spaces' do
          msg = 'feature is missing, action route must be like <feature/action>'
          expect {
            create_request('  /  ', {})
          }.to raise_error(RuntimeError, msg)
        end

        it 'ignores anything more than one forward slash' do
          request = create_request('foo/bar/baz', {})
          expect(request.action_route).to eq 'foo/bar/baz'
          expect(request.feature).to eq 'foo'
          expect(request.action).to eq 'bar'
        end
      end

      context 'initializing with inputs' do
        it 'assigns inputs when they are a hash' do
          inputs = {a: 'a', b: 'b'}
          request = create_request('foo/bar', inputs)
          expect(request.inputs).to eq inputs
        end

        it 'assigns inputs when inputs implements to_h' do
          inputs = {a: 'a', b: 'b'}
          data = Object.new
          data.instance_eval do
            define_singleton_method(:to_h) do
              inputs
            end
          end
          request = create_request('foo/bar', data)
          expect(request.inputs).to eq inputs
        end

        it 'fails when inputs does not implement to_h' do
          inputs = Object.new
          msg = "inputs must respond to :to_h"
          expect {
            create_request('foo/bar', inputs)
          }.to raise_error(RuntimeError, msg)
        end
      end

      def create_request(route, inputs)
        Request.new(route, inputs)
      end
    end
  end
end
