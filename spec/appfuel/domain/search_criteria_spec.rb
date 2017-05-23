module Appfuel::Domain
  RSpec.describe BaseCriteria do
    context 'initialize' do
      it 'initializes with no expressions when given no args' do
        criteria = create_criteria('foo.bar')
        expect(criteria.filters?).to be false
      end
    end

    def create_criteria(domain_name, settings = {})
      SearchCriteria.new(domain_name, settings)
    end
  end
end
