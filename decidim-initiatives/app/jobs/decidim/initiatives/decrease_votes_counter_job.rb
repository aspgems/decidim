# frozen_string_literal: true

module Decidim
  module Initiatives
    class DecreaseVotesCounterJob < ApplicationJob
      queue_as :default

      def perform(initiative_id, scope_ids)
        return unless Decidim::Initiative.where(id: initiative_id).exists?

        ActiveRecord::Base.connection.execute update_query(initiative_id, scope_ids)
      end

      def update_query(initiative_id, scope_ids)
        <<~SQL
          UPDATE decidim_initiatives
             SET online_votes = online_votes || CONCAT('{', #{online_votes_parts(scope_ids)}, '}')::jsonb
           WHERE id = #{initiative_id};
        SQL
      end

      def online_votes_parts(scope_ids)
        (total_json(scope_ids.size) + scopes_json(scope_ids)).flatten.join(", ")
      end

      def total_json(total)
        [%('"total":'), "(online_votes->>'total')::int - #{total}"]
      end

      def scopes_json(scope_ids)
        scope_ids.map do |scope_id|
          [%(', "#{scope_id}":'), "(online_votes->>'#{scope_id}')::int - 1"]
        end
      end
    end
  end
end
