module Appfuel
  module Db
    class Repository < Appfuel::Repository::Base
      include RepositoryQuery
      include Mapper
    end
  end
end
