# frozen_string_literal: true

module Decidim
  module Initiatives
    class IncreaseVotesCounterJob < ApplicationJob
      queue_as :default

      def perform(initiative_id, scope_ids, max_vote_id)
        return unless Decidim::Initiative.where(id: initiative_id).exists?

        ActiveRecord::Base.connection.execute update_query(initiative_id, scope_ids, max_vote_id)
        Decidim::Initiatives::NotifyInitiativesMilestonesJob.perform_now(initiative_id)
        Decidim::Initiatives::NotifyInitiativesEndorsementJob.perform_now(initiative_id)
      end

      def update_query(initiative_id, scope_ids, max_vote_id)
        <<~SQL
          UPDATE decidim_initiatives
             SET last_counted_vote_id = #{max_vote_id},
                 online_votes = online_votes || CONCAT('{', #{online_votes_parts(scope_ids)}, '}')::jsonb
           WHERE id = #{initiative_id};
        SQL
      end

      def online_votes_parts(scope_ids)
        (total_json(scope_ids.size) + scopes_json(scope_ids)).flatten.join(", ")
      end

      def total_json(votes)
        [%('"total":'), "COALESCE(online_votes->>'total', '0')::int + #{votes}"]
      end

      def scopes_json(scope_ids)
        scope_ids.map do |scope_id|
          [%(', "#{scope_id}":'), "COALESCE(online_votes->>'#{scope_id}', '0')::int + 1"]
        end
      end
    end
  end
end
