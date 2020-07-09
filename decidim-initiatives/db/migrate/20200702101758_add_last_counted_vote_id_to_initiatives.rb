class AddLastCountedVoteIdToInitiatives < ActiveRecord::Migration[5.2]
  def change
    add_reference :decidim_initiatives, :last_counted_vote, index: false
  end
end
