module Appfuel
  RSpec.describe Response do
    it 'assumes ok if no errors hash is given' do
      response = create_response('some response')
      expect(response.ok?).to be true
      expect(response.errors?).to be false
    end

    it 'returns value given as a string' do
      response = create_response('some response')
      expect(response.ok).to eq 'some response'
      expect(response.errors).to eq nil
    end

    it 'returns value given as an hash' do
      value = {foo: 'bar'}
      response = create_response(value)
      expect(response.ok).to eq value
    end

    it 'converts an object to a hash' do
      obj = Object.new
      def obj.to_h
        {foo: 'bar'}
      end
      response = create_response(obj)
      expect(response.ok).to eq(obj.to_h)
    end

    it 'converts an object to a string if it does not support to_h' do
      obj = Object.new
      response = create_response(obj)
      expect(response.ok).to eq(obj.to_s)
    end

    context '.errors?' do
      it 'believes has hash with the symbol errors is an error state' do
        response = create_response(errors: {blah: ['this is test']})
        expect(response.errors?).to be true
        expect(response.ok?).to be false
      end

      it 'returns errors when in an error state ' do
        response = create_response(errors: {blah: ['this is a test']})
        expect(response.error_messages).to eq({"blah" => ['this is a test']})
        expect(response.ok).to eq nil
      end

      it 'thinks an object that converts to a hash with errors key is an error' do
        obj = Object.new
        def obj.to_h
          {
            errors: {
              key: ['message']
            }
          }
        end
        response = create_response(obj)
        expect(response.ok?).to  be false
        expect(response.errors?).to  be true
      end

      it 'has an alias called failure?' do
        response = Response.ok('blah')
        expect(response.method(:errors?)).to eq(response.method(:failure?))
      end
    end

    context '.ok?' do
      it 'has an alias called success?' do
        response = Response.ok('blah')
        expect(response.method(:ok?)).to eq(response.method(:success?))
      end

      it 'thinks an object that supports to_s is successfull' do
        obj = Object.new
        response = create_response(obj)
        expect(response.ok?).to be true
        expect(response.errors?).to be false
      end

      it 'thinks a hash without an errors key is successfull' do
        value = {foo: 'bar'}
        response = create_response(value)
        expect(response.ok?).to be true
        expect(response.errors?).to be false
      end

      it 'thinks an object that converts to a hash with no errors key is ok' do
        obj = Object.new
        def obj.to_h
          {foo: 'bar'}
        end
        response = create_response(obj)
        expect(response.ok?).to be true
        expect(response.errors?).to be false
      end



    end

    context '.to_h' do
      it 'converts only ok to hash and includes ok key' do
        result = 'my result'
        response = create_response(result)
        expect(response.to_h).to eq({ok: 'my result'})
      end

      it 'converts only errors to hash when in error state' do
        result = {errors: {key: 'value'}}
        response = create_response(result)
        expect(response.to_h).to eq result
      end
    end

    context '#ok' do
      it 'is an easy way to make a successful response' do
        value = 'i am good'
        response = Response.ok(value)
        expect(response).to be_an_instance_of(Response)
        expect(response.ok?).to be true
        expect(response.ok).to eq value
        expect(response.errors?).to be false
        expect(response.errors).to eq nil
        expect(response.to_h).to eq({ok: value})
      end
    end

    context '#errors' do
      it 'is an easy way to  create an error response' do
        value = { errors: { foo: ['test'] } }
        response = Response.error(value)
        expect(response).to be_an_instance_of(Response)
        expect(response.ok?).to be false
        expect(response.ok).to eq nil
        expect(response.errors?).to be true
        expect(response.error_messages).to eq value[:errors]
        expect(response.to_h).to eq value
      end
    end

    def create_response(data)
      Response.new(data)
    end
  end
end
