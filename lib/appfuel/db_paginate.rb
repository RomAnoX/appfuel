module SpCore
  module DbPaginate
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def paginate(overrides = {})
        page = overrides.fetch(:page, 1)
        per_page = overrides.fetch(:per_page, default_per_page)
        total = self.count
        offset = (page - 1) * per_page

        result = self.offset(offset).limit(per_page)

        result = result.extend(PaginatedActiveRecord)

        result.send(:set_metadata!, {
          page: page,
          per_page: per_page,
          total_items: total,
          total_pages: total / per_page
        })

        result
      end

      def results_per_page(per_page)
        @default_per_page = per_page
      end

      def default_per_page
        @default_per_page ||= 10
      end

    end

    module PaginatedActiveRecord
      attr_reader :page, :per_page, :total_pages, :total_items

      private

      def set_metadata!(metadata)
        @page = metadata[:page]
        @per_page = metadata[:per_page]
        @total_pages = metadata[:total_pages]
        @total_items = metadata[:total_items]
      end

    end

  end
end
