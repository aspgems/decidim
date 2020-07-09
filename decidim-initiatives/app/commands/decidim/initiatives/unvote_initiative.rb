# frozen_string_literal: true

module Decidim
  module Initiatives
    # A command with all the business logic when a user or organization unvotes an initiative.
    class UnvoteInitiative < Rectify::Command
      # Public: Initializes the command.
      #
      # initiative   - A Decidim::Initiative object.
      # current_user - The current user.
      def initialize(initiative, current_user)
        @initiative = initiative
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the initiative.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        unvotes = destroy_initiative_vote
        update_votes_counter(unvotes)
        broadcast(:ok, @initiative)
      end

      private

      def destroy_initiative_vote
        Initiative.transaction do
          @initiative.votes.where(author: @current_user).destroy_all
        end
      end

      def update_votes_counter(unvotes)
        pending_uncount_votes = unvotes.select { |unvote| unvote.id <= (@initiative.last_counted_vote_id || 0) }
        return if pending_uncount_votes.empty?

        if Decidim::Initiatives.unvotes_counting_mode == :sync
          DecreaseVotesCounterJob.perform_now(@initiative.id, pending_uncount_votes.map(&:decidim_scope_id))
        else
          DecreaseVotesCounterJob.perform_later(@initiative.id, pending_uncount_votes.map(&:decidim_scope_id))
        end
      end
    end
  end
end
