module Appfuel::Domain
  RSpec.describe DomainNameParser do

    context '#parse_domain_name' do
      it 'parses "foo.bar" into ["foo", "bar", "foo.bar"]' do
        parser = setup
        result = parser.parse_domain_name('foo.bar')
        expect(result).to eq(["foo", "bar", "foo.bar"])
      end

      it 'fails if the name is not a string or does not support domain_name' do
        parser = setup
        msg = "domain name must be a string or implement method :domain_name"
        expect {
          parser.parse_domain_name(123)
        }.to raise_error(msg)
      end

      it 'parses an object that implements :domain_name' do
        domain = double('some domain')
        parser = setup

        allow(domain).to receive(:domain_name).with(no_args) { 'foo.bar' }
        result = parser.parse_domain_name(domain)
        expect(result).to eq(["foo", "bar", "foo.bar"])
      end

      it 'fails when domain name has no feature/global component' do
        parser = setup
        msg = "domain names must be in the form of (<feature|global>.domain)"
        expect {
          parser.parse_domain_name('foo')
        }.to raise_error(msg)
      end
    end

    context '#parse_domain_attr' do
      it 'parses "foo.bar.id" into ["foo.bar", "id"]' do
        parser = setup
        result = parser.parse_domain_attr('foo.bar.id')
        expect(result).to eq(["foo.bar", "id"])
      end

      it 'parses "foo.bar.baz.bam.id" into ["foo.bar.baz.bam", "id"]' do
        parser = setup
        result = parser.parse_domain_attr('foo.bar.baz.bam.id')
        expect(result).to eq(["foo.bar.baz.bam", "id"])
      end

      it 'fails when not a string' do
        parser = setup
        msg = "domain attribute name must be a string"
        expect {
          parser.parse_domain_attr(123)
        }.to raise_error(msg)
      end
    end

    def setup
      object = Object.new
      object.extend(DomainNameParser)
      object
    end
  end
end
