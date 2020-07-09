# frozen_string_literal: true

module Decidim
  module Initiatives
    # A command with all the business logic when a user or organization votes an initiative.
    class VoteInitiative < Rectify::Command
      # Public: Initializes the command.
      #
      # form - A form object with the params.
      def initialize(form)
        @form = form
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the proposal vote.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        Initiative.transaction do
          create_votes
        end

        update_votes_counter

        broadcast(:ok, votes)
      end

      attr_reader :votes

      private

      attr_reader :form

      delegate :initiative, to: :form

      def create_votes
        @votes = form.authorized_scopes.map do |scope|
          initiative.votes.create!(
            author: form.signer,
            encrypted_metadata: form.encrypted_metadata,
            timestamp: timestamp,
            hash_id: form.hash_id,
            scope: scope
          )
        end
      end

      def timestamp
        return unless timestamp_service

        @timestamp ||= timestamp_service.new(document: form.encrypted_metadata).timestamp
      end

      def timestamp_service
        @timestamp_service ||= Decidim.timestamp_service.to_s.safe_constantize
      end

      def update_votes_counter
        # If mode is batch, we do nothing here, it will be done in a separate process
        if Decidim::Initiatives.votes_counting_mode == :sync
          IncreaseVotesCounterJob.perform_now(initiative.id, @votes.map(&:decidim_scope_id), @votes.map(&:id).max)
        elsif Decidim::Initiatives.votes_counting_mode == :async
          IncreaseVotesCounterJob.perform_later(initiative.id, @votes.map(&:decidim_scope_id), @votes.map(&:id).max)
        end
      end
    end
  end
end
