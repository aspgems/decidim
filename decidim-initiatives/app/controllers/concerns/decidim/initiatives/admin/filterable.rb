# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Initiatives
    module Admin
      module Filterable
        extend ActiveSupport::Concern

        included do
          include Decidim::Admin::Filterable

          private

          def base_query
            collection.left_joins(:area)
          end

          def search_field_predicate
            :title_or_description_cont
          end

          def filters
            [:state_eq, :decidim_area_id_eq]
          end

          def filters_with_values
            {
              state_eq: Initiative.states.keys,
              decidim_area_id_eq: current_organization.areas.pluck(:id)
            }
          end

          def dynamically_translated_filters
            [:decidim_area_id_eq]
          end

          def translated_decidim_area_id_eq(id)
            translated_attribute(Decidim::Area.find_by(id: id).name[I18n.locale.to_s])
          end
        end
      end
    end
  end
end
