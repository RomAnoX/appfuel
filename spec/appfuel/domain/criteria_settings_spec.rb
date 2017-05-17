module Appfuel::Domain
  RSpec.describe CriteriaSettings do
    context 'initialize' do
    end

    def create_settings(settings = {})
      CriteriaSettings.new(settings)
    end
  end
end
