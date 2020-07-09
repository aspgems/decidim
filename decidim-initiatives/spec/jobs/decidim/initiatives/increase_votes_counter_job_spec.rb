# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Initiatives
    describe IncreaseVotesCounterJob do
      let(:organization) { create :organization }
      let(:initiative) do
        create(:initiative,
               organization: organization,
               scoped_type: create(
                 :initiatives_type_scope,
                 supports_required: 1000,
                 type: create(:initiatives_type, organization: organization)
               ))
      end
      let(:confirmed_user) { create(:user, :confirmed, organization: initiative.organization) }
      let(:vote) { initiative.votes.create(author: confirmed_user, scope: initiative.scope) }

      it "calls to notify milestones" do
        vote.save!
        expect(Decidim::Initiatives::NotifyInitiativesMilestonesJob)
          .to receive(:perform_now)
          .with(initiative.id)

        perform_enqueued_jobs do
          described_class.perform_now(initiative.id, [vote.decidim_scope_id], vote.id)
        end
      end

      it "calls to notify endorsement" do
        vote.save!
        expect(Decidim::Initiatives::NotifyInitiativesEndorsementJob)
          .to receive(:perform_now)
          .with(initiative.id)

        perform_enqueued_jobs do
          described_class.perform_now(initiative.id, [vote.decidim_scope_id], vote.id)
        end
      end

      it "updates the last counted vote" do
        vote.save!
        expect(initiative.last_counted_vote_id).to be_nil

        perform_enqueued_jobs do
          described_class.perform_now(initiative.id, [vote.decidim_scope_id], vote.id)
        end

        expect(initiative.reload.last_counted_vote_id).to eq(vote.id)
      end

      context "with an uncounted initiative" do
        it "sets the current votes" do
          vote.save!
          expect(initiative.online_votes).to eq({})

          perform_enqueued_jobs do
            described_class.perform_now(initiative.id, [vote.decidim_scope_id], vote.id)
          end

          expect(initiative.reload.online_votes).to eq("total" => 1, vote.decidim_scope_id.to_s => 1)
        end
      end

      context "with a counted initiative" do
        before do
          create(:initiative_user_vote, initiative: initiative)
        end

        it "adds the current votes" do
          vote.save!
          expect(initiative.online_votes).to eq("total" => 1, vote.decidim_scope_id.to_s => 1)

          perform_enqueued_jobs do
            described_class.perform_now(initiative.id, [vote.decidim_scope_id], vote.id)
          end

          expect(initiative.reload.online_votes).to eq("total" => 2, vote.decidim_scope_id.to_s => 2)
        end
      end
    end
  end
end
