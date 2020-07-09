# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Initiatives
    describe DecreaseVotesCounterJob do
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
      let!(:vote) { create(:initiative_user_vote, initiative: initiative) }

      it "subtracts the current votes" do
        expect(initiative.online_votes).to eq("total" => 1, vote.decidim_scope_id.to_s => 1)

        perform_enqueued_jobs do
          described_class.perform_now(initiative.id, [vote.decidim_scope_id])
        end

        expect(initiative.reload.online_votes).to eq("total" => 0, vote.decidim_scope_id.to_s => 0)
      end
    end
  end
end
