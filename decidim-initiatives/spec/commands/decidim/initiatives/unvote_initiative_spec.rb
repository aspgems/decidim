# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Initiatives
    describe UnvoteInitiative do
      describe "User unvotes initiative" do
        let!(:vote) { create(:initiative_user_vote) }
        let(:command) { described_class.new(vote.initiative, vote.author) }
        let(:initiative) { vote.initiative }

        it "broadcasts ok" do
          expect { command.call }.to broadcast :ok
        end

        it "Removes the vote" do
          expect do
            command.call
          end.to change(InitiativesVote, :count).by(-1)
        end

        context "when the vote was already counted" do
          it "decreases the vote counter by one" do
            expect(InitiativesVote.count).to eq(1)
            expect do
              command.call
              initiative.reload
            end.to change { initiative.online_votes_count }.by(-1)
          end
        end

        context "when vote was not counted yet" do
          let(:confirmed_user) { create(:user, :confirmed, organization: initiative.organization) }
          let!(:uncounted_vote) { initiative.votes.create(author: confirmed_user, scope: initiative.scope) }
          let(:command) { described_class.new(uncounted_vote.initiative, uncounted_vote.author) }

          it "does not decrease the vote counter" do
            expect(InitiativesVote.count).to eq(2)
            expect do
              command.call
              initiative.reload
            end.not_to change { initiative.online_votes_count }
          end
        end
      end
    end
  end
end
