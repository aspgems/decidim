# frozen_string_literal: true

module Decidim
  module Initiatives
    # Service to update the counters of votes
    class InitiativeVotesUpdater
      def initialize(initiative)
        @initiative = initiative
      end

      def update_votes_counter
        # Initiatives without new votes shouldn't get here, they should be filtered in the rake task
        # but just in case this is called from somewhere else, return if no new votes
        return if data[:max_id].zero?

        ActiveRecord::Base.connection.execute update_query
        Decidim::Initiatives::NotifyInitiativesMilestonesJob.perform_now(@initiative.id)
        Decidim::Initiatives::NotifyInitiativesEndorsementJob.perform_now(@initiative.id)
      end

      private

      attr_reader :initiative

      def update_query
        <<~SQL
          UPDATE decidim_initiatives
             SET last_counted_vote_id = #{data.delete(:max_id)},
                 online_votes = online_votes || CONCAT('{', #{online_votes_parts}, '}')::jsonb
           WHERE id = #{initiative.id};
        SQL
      end

      def data
        @data ||= calculate_data
      end

      def calculate_data
        initiative
          .votes
          .where("id > ?", initiative.last_counted_vote_id || 0)
          .group(:decidim_scope_id)
          .pluck("COUNT(*)", :decidim_scope_id, "MAX(id)")
          .each_with_object(total: 0, max_id: 0) do |(count, scope_id, max_id), hash|
          hash[scope_id || "global"] = count
          hash[:total] += count
          hash[:max_id] = [hash[:max_id], max_id].max
        end
      end

      def online_votes_parts
        (total_json + scopes_json).flatten.join(", ")
      end

      def total_json
        [%('"total":'), "COALESCE(online_votes->>'total', '0')::int + #{data.delete(:total)}"]
      end

      def scopes_json
        data.map do |scope_id, value|
          [%(', "#{scope_id}":'), "COALESCE(online_votes->>'#{scope_id}', '0')::int + #{value}"]
        end
      end
    end
  end
end
