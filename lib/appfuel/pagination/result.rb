module Appfuel
  module Pagination
    class Result < Domain::ValueObject
      attribute 'page_size',     'int', gt: 0, default: 1
      attribute 'page_limit',    'int', gt: 0, default: 20
      attribute 'total_count',   'int', gt: 0
      attribute 'current_page',  'int'
    end
  end
end
