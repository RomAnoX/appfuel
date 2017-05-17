module Appfuel::Domain
  RSpec.describe BaseCriteria do
    context 'initialize' do
      it 'creates a criteria with a feature name' do
        criteria = create_base_criteria('foo.bar')
        expect(criteria.feature).to eq 'foo'
      end

      it 'creates a criteria with a feature and domain' do
        criteria = create_base_criteria('foo.bar')
        expect(criteria.domain_basename).to eq 'bar'
      end

      it 'creates a criteria with only a domain no feature' do
        criteria = create_base_criteria('bar')
        expect(criteria.domain_basename).to eq 'bar'
      end

      it 'returns Types::Undefined for feature that is not defined' do
        criteria = create_base_criteria('bar')
        expect(criteria.feature).to eq nil
      end

      it 'returns feature when domain supports :domain_name' do
        domain = instance_double('Some Domain')
        allow(domain).to receive(:domain_name).with(no_args) { 'foo.bar' }
        criteria = create_base_criteria(domain)
        expect(criteria.feature).to eq 'foo'
        expect(criteria.domain_basename).to eq 'bar'
      end

      it 'fails when domain is not a string' do
        msg = 'domain name must be a string or implement method :domain_name'
        expect {
          create_base_criteria(12345)
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when domain nil' do
        msg = 'domain name must be a string or implement method :domain_name'
        expect {
          create_base_criteria(nil)
        }.to raise_error(RuntimeError, msg)
      end

      it 'is created with empty expr list' do
        expect(create_base_criteria('foo').exprs).to eq(nil)
      end
    end

    context '#add_param' do

      it 'returns nil if not param' do
        expect {
          create_base_criteria('foo.bar').add_param(nil, nil)
        }.to raise_error('key should not be nil')
      end

      it 'returns the value added' do
        result = create_base_criteria('foo.bar').add_param('my_key', 100)
        expect(result).to eq 100
      end

      it 'should added value' do
        value = 99
        criteria = create_base_criteria('foo.bar')
        criteria.add_param('my_key', value)

        expect(criteria.params?).to be_truthy
        expect(criteria.param(:my_key)).to eq value
        expect(criteria.param?(:my_key)).to be_truthy
      end
    end

    def create_base_criteria(domain_name, settings = {})
      BaseCriteria.new(domain_name, settings)
    end
  end
end
