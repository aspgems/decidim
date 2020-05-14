# frozen_string_literal: true

require "spec_helper"

describe "Admin manages initiatives", type: :system do
  STATES = Decidim::Initiative.states.keys.map(&:to_sym)

  def create_initiative_with_trait(trait)
    create(:initiative, trait, organization: organization)
  end

  def initiative_with_state(state)
    Decidim::Initiative.find_by(state: state)
  end

  def initiative_without_state(state)
    Decidim::Initiative.where.not(state: state).sample
  end

  def initiative_with_area(area)
    Decidim::Initiative.find_by(decidim_area_id: area)
  end

  def initiative_without_area(area)
    Decidim::Initiative.where.not(decidim_area_id: area).sample
  end

  include_context "with filterable context"

  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:model_name) { Decidim::Initiative.model_name }
  let(:area1) { create :area, organization: organization }
  let(:area2) { create :area, organization: organization }

  STATES.each do |state|
    let!("#{state}_initiative") { create_initiative_with_trait(state) }
  end

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_admin_initiatives.initiatives_path
  end

  describe "listing initiatives" do
    STATES.each do |state|
      i18n_state = I18n.t(state, scope: "decidim.admin.filters.state_eq.values")

      context "filtering collection by state: #{i18n_state}" do
        it_behaves_like "a filtered collection", options: "State", filter: i18n_state do
          let(:in_filter) { translated(initiative_with_state(state).title) }
          let(:not_in_filter) { translated(initiative_without_state(state).title) }
        end
      end
    end

    Decidim::Area.all.each do |area|
      i18n_area = area.name[I18n.locale.to_s]

      context "filtering collection by area: #{i18n_area}" do
        before do
          create(:initiative, organization: organization, area: area1)
          create(:initiative, organization: organization, area: area2)
        end

        it_behaves_like "a filtered collection", options: "Area", filter: i18n_area do
          let(:in_filter) { translated(initiative_with_area(area).title) }
          let(:not_in_filter) { translated(initiative_without_area(area).title) }
        end
      end
    end

    it "can be searched by description" do
      search_by_text(translated(published_initiative.description))

      expect(page).to have_content(translated(published_initiative.title))
    end

    it_behaves_like "paginating a collection"
  end
end
