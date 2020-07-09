# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Initiatives
    describe NotifyInitiativesMilestonesJob do
      let(:organization) { create(:organization) }
      let(:initiative) do
        create(:initiative,
               organization: organization,
               scoped_type: create(
                 :initiatives_type_scope,
                 supports_required: 4,
                 type: create(:initiatives_type, organization: organization)
               ),
               milestones: [25])
      end

      before do
        create(:initiative_user_vote, initiative: initiative)
        create(:initiative_user_vote, initiative: initiative)
      end

      it "notifies the new milestone" do
        follower = create(:user, organization: organization)
        create(:follow, followable: initiative, user: follower)

        expect(Decidim::EventsManager)
          .to receive(:publish)
                .with(
                  event: "decidim.events.initiatives.milestone_completed",
                  event_class: Decidim::Initiatives::MilestoneCompletedEvent,
                  resource: initiative,
                  affected_users: [initiative.author],
                  followers: [follower],
                  extra: { percentage: 50 }
                )

        perform_enqueued_jobs do
          described_class.perform_now(initiative.id)
        end
      end

      it "saves the new milestone in the initiative" do
        perform_enqueued_jobs do
          described_class.perform_now(initiative.id)
        end

        expect(initiative.reload.milestones).to eq([25, 50])
      end
    end
  end
end
