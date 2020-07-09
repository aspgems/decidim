# frozen_string_literal: true

module Decidim
  module Initiatives
    class NotifyInitiativesEndorsementJob < ApplicationJob
      queue_as :default

      def perform(initiative_id)
        initiative = Decidim::Initiative.find_by(id: initiative_id)
        return unless initiative

        notify_endorsement(initiative)
      end

      def notify_endorsement(initiative)
        Decidim::EventsManager.publish(
          event: "decidim.events.initiatives.initiative_endorsed",
          event_class: Decidim::Initiatives::EndorseInitiativeEvent,
          resource: initiative,
          followers: initiative.author.followers
        )
      end
    end
  end
end
