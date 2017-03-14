module Appfuel
  RSpec.describe ResponseHandler do
    context '#response?' do
      it 'returns true when object is an instance of Response' do
        cmd = setup
        response = Response.new
        expect(cmd.response?(response)).to be true
      end

      it 'returns false when not a response class' do
        cmd = setup
        expect(cmd.response?('foo')).to be false
      end
    end

    context '#ok' do
      it 'returns a Response object' do
        cmd = setup
        expect(cmd.ok).to be_an_instance_of(response_class)
      end

      it 'returns a response with a nil value' do
        cmd = setup
        response = cmd.ok
        expect(response.ok?).to be true
        expect(response.ok).to eq nil
      end

      it 'returns a response with a scalar value' do
        cmd = setup
        response = cmd.ok(123)
        expect(response.ok?).to be true
        expect(response.ok).to eq 123
      end

      it 'returns a response with a hash' do
        cmd = setup
        response = cmd.ok(foo: 'bar')
        expect(response.ok?).to be true
        expect(response.ok).to eq({foo: 'bar'})
      end

      it 'returns a response that is ok even when hash as key errors' do
        cmd    = setup
        errors = {errors: {foo: ['some error']}}
        response = cmd.ok(errors) # this is not considered an error
        expect(response.ok?).to be true
        expect(response.ok).to eq(errors)
      end

      it 'returns an object' do
        cmd = setup
        obj = Object.new
        response = cmd.ok(obj)

        expect(response.ok?).to be true
        expect(response.ok).to eq obj
      end
    end

    context 'errors' do
      it 'converts a ActiveModel::Errors into a hash of messages' do
        cmd     = setup
        errors  = ActiveModel::Errors.new(:foo)
        errors.add(:error_a, 'message_a')
        response = cmd.error(errors)
        expect(response.errors?).to be true
        expect(response.error_messages).to eq({"error_a" => ['message_a']})
      end

      it 'translates a StandardError into a hash' do
        msg = 'some error'
        cmd = setup
        error = StandardError.new(msg)
        response = cmd.error(error)
        expected = {
          "standard_error" => [msg],
          "standard_error_backtrace" => []
        }
        expect(response.errors?).to be true
        expect(response.error_messages).to eq expected
      end

      it 'accepts a hash with the key :errors as an error response' do
        error = {errors: {error_a: ['this is an error']}}
        cmd   = setup
        response = cmd.error(error)
        expect(response.errors?).to be true
        expect(response.error_messages).to eq error[:errors]
      end

      it 'accepts a hash with no errors error as an error response' do
        error = {"error_a" => ['this is an error']}
        cmd   = setup
        response = cmd.error(error)
        expect(response.errors?).to be true
        expect(response.error_messages).to eq error
      end

      it 'accepts an SpCore::Errors object as an error response' do
        error = Errors.new(error_a: ['This is an error'])
        cmd   = setup
        response = cmd.error(error)
        expect(response.errors?).to be true
        expect(response.error_messages).to eq({"error_a" => ['This is an error']})
      end

      it 'accepts a symobol followed my a message as an error response' do
        cmd = setup
        response = cmd.error(:error_a, 'This is an error')

        expect(response.errors?).to be true
        expect(response.error_messages).to eq({"error_a" => ['This is an error']})
      end

      it 'returns a response if its passed in' do
        cmd = setup
        error = Response.new(errors: {error_a: ['this is an error']})
        response = cmd.error(error)
        expect(response).to eq error
      end

      it 'accepts a string as general error' do
        cmd = setup
        response = cmd.error('This is an error')

        expect(response.errors?).to be true
        expect(response.error_messages).to eq({"general_error" => ['This is an error']})
      end
    end

    context '#error_data?' do
      it 'returns true when data is a StandardError' do
        cmd = setup
        expect(cmd.error_data?(StandardError.new('a'))).to be true
      end

      it 'returns true when data inherits from StandardError' do
        cmd = setup
        expect(cmd.error_data?(RuntimeError.new('a'))).to be true
      end

      it 'returns true when a hash has the key :errors' do
        cmd = setup
        error = {errors: 'blah'}
        expect(cmd.error_data?(error)).to be true
      end

      it 'returns false for an empty hash' do
        cmd = setup
        expect(cmd.error_data?({})).to be false
      end

      it 'returns false for a hash that has no errors key' do
        cmd = setup
        expect(cmd.error_data?({foo: 'bar'})).to be false
      end

      it 'returns false for a nil' do
        cmd = setup
        expect(cmd.error_data?(nil)).to be false
      end

      it 'returns false for a scalar value' do
        cmd = setup
        expect(cmd.error_data?(1234)).to be false
      end
    end

    context '#create_response' do
      it 'returns the back the same reponse when a response is passed in' do
        cmd = setup
        response = response_class.new(ok: 'blah')
        expect(cmd.create_response(response)).to eq response
      end

      it 'returns back the same response when it is an error response' do
        cmd = setup
        response = response_class.new(errors: {foo: ['error']})
        expect(cmd.create_response(response)).to eq response
      end

      it 'creates an error response when data is a StandardError' do
        cmd   = setup
        error = StandardError.new('a')
        response = cmd.create_response(error)
        expected = {
          "standard_error" => ['a'],
          "standard_error_backtrace" => []
        }
        expect(response).to be_an_instance_of(response_class)
        expect(response.errors?).to be true
        expect(response.error_messages).to eq(expected)
      end


      it 'creates an error response when data inherits from StandardError' do
        cmd   = setup
        error = RuntimeError.new('a')
        response = cmd.create_response(error)
        expected = {
          "runtime_error" => ['a'],
          "runtime_error_backtrace" => []
        }
        expect(response).to be_an_instance_of(response_class)
        expect(response.errors?).to be true
        expect(response.error_messages).to eq(expected)
      end

      it 'creates an error response when a hash has the key :errors' do
        cmd   = setup
        error = {errors: {foo: ['error']}}
        response = cmd.create_response(error)
        expect(response).to be_an_instance_of(response_class)
        expect(response.errors?).to be true
        expect(response.error_messages).to eq({"foo" => ['error']})
      end

      it 'creates an ok response when not an error' do
        cmd  = setup
        data = ['a', 'b', 'c']
        response = cmd.create_response(data)
        expect(response).to be_an_instance_of(response_class)
        expect(response.ok?).to be true
        expect(response.ok).to eq data
      end
    end

    def setup
      ResponseHandler.new
    end

    def response_class
      Response
    end

    def create_container
      Dry::Container.new
    end
  end
end
