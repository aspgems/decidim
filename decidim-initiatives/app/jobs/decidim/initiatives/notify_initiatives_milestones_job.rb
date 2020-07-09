# frozen_string_literal: true

module Decidim
  module Initiatives
    class NotifyInitiativesMilestonesJob < ApplicationJob
      MILESTONES = [25, 50, 75, 100].freeze

      queue_as :default

      def perform(initiative_id)
        initiative = Decidim::Initiative.find_by(id: initiative_id)
        return unless initiative

        notify_percentage_change(initiative)
      end

      def notify_percentage_change(initiative)
        percentages = MILESTONES.select do |milestone|
          initiative.percentage >= milestone && !milestone.in?(initiative.milestones)
        end

        return if percentages.empty?

        percentages.each do |percentage|
          notify_milestone_completed(initiative, percentage)
          notify_support_threshold_reached(initiative) if percentage == 100
          initiative.milestones.append(percentage)
        end

        initiative.save!
      end

      def notify_milestone_completed(initiative, percentage)
        Decidim::EventsManager.publish(
          event: "decidim.events.initiatives.milestone_completed",
          event_class: Decidim::Initiatives::MilestoneCompletedEvent,
          resource: initiative,
          affected_users: [initiative.author],
          followers: initiative.followers - [initiative.author],
          extra: {
            percentage: percentage
          }
        )
      end

      def notify_support_threshold_reached(initiative)
        Decidim::EventsManager.publish(
          event: "decidim.events.initiatives.support_threshold_reached",
          event_class: Decidim::Initiatives::Admin::SupportThresholdReachedEvent,
          resource: initiative,
          followers: Decidim::User.where(organization: initiative.organization, admin: true)
        )
      end
    end
  end
end
