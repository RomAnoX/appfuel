module Appfuel
  RSpec.describe Handler do
    context '.response_handler' do
      it 'defaults to Appfuel::ResponseHandler' do
        handler_class = Handler
        expect(handler_class.response_handler).to be_an_instance_of(ResponseHandler)
      end
    end
  end
end
