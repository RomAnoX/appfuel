module Appfuel::Validation
  RSpec.describe ValidatorPipe do
    describe '#initialize' do
      it 'requires a name and a block' do
        pipe = ValidatorPipe.new('foo') do |inputs, data|
          # nothing to see here
        end
        expect(pipe.name).to eq('foo')
        expect(pipe.code).to be_an_instance_of(Proc)
      end

      it 'fail when no block is given' do
        msg = 'block is required'
        expect {
          ValidatorPipe.new('foo')
        }.to raise_error(ArgumentError, msg)
      end

      it 'defaults to an empty dependency hash' do
        pipe = ValidatorPipe.new('foo'){|inputs, data| }
        expect(pipe.dependencies).to be_empty
      end
    end
  end
end
