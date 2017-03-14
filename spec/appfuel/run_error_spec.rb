module Appfuel
  RSpec.describe RunError do
    it 'inherits from StandardError' do
      expect(RunError).to be < StandardError
    end

    it 'assigns a response object when initializing' do
      response = instance_double(Response)
      error = RunError.new(response)
      expect(error.response).to eq response
    end
  end
end
