# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Initiatives
    describe NotifyInitiativesEndorsementJob do
      let(:organization) { create(:organization) }
      let(:initiative) { create(:initiative, organization: organization) }

      it "notifies the vote" do
        follower = create(:user, organization: organization)
        create(:follow, followable: initiative.author, user: follower)

        expect(Decidim::EventsManager)
          .to receive(:publish)
                .with(
                  event: "decidim.events.initiatives.initiative_endorsed",
                  event_class: Decidim::Initiatives::EndorseInitiativeEvent,
                  resource: initiative,
                  followers: [follower]
                )

        perform_enqueued_jobs do
          described_class.perform_now(initiative.id)
        end
      end
    end
  end
end
