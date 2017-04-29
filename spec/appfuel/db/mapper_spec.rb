module Appfuel::Db
  RSpec.describe Mapper do


    def setup_mapper
      obj = Object.new
      obj.extend(Mapper)
      obj
    end
  end
end
