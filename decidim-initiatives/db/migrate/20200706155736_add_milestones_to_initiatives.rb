class AddMilestonesToInitiatives < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_initiatives, :milestones, :integer, array: true, default: []
  end
end
