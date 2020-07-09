# frozen_string_literal: true

require "decidim/initiatives/admin"
require "decidim/initiatives/engine"
require "decidim/initiatives/admin_engine"
require "decidim/initiatives/participatory_space"

module Decidim
  # Base module for the initiatives engine.
  module Initiatives
    include ActiveSupport::Configurable

    # Public setting that defines whether creation is allowed to any validated
    # user or not. Defaults to true.
    config_accessor :creation_enabled do
      true
    end

    # Public Setting that defines the similarity minimum value to consider two
    # initiatives similar. Defaults to 0.25.
    config_accessor :similarity_threshold do
      0.25
    end

    # Public Setting that defines how many similar initiatives will be shown.
    # Defaults to 5.
    config_accessor :similarity_limit do
      5
    end

    # Minimum number of committee members required to pass the initiative to
    # technical validation phase. Only applies to initiatives created by
    # individuals.
    config_accessor :minimum_committee_members do
      2
    end

    # Number of days available to collect supports after an initiative has been
    # published.
    config_accessor :default_signature_time_period_length do
      120
    end

    # Components enabled for a new initiative
    config_accessor :default_components do
      [:pages, :meetings]
    end

    # Notifies when the given percentage of supports is reached for an
    # initiative.
    config_accessor :first_notification_percentage do
      33
    end

    # Notifies when the given percentage of supports is reached for an
    # initiative.
    config_accessor :second_notification_percentage do
      66
    end

    # Sets the expiration time for the statistic data.
    config_accessor :stats_cache_expiration_time do
      5.minutes
    end

    # Maximum amount of time in validating state.
    # After this time the initiative will be moved to
    # discarded state.
    config_accessor :max_time_in_validating_state do
      60.days
    end

    # Print functionality enabled. Allows the user to get
    # a printed version of the initiative from the administration
    # panel.
    config_accessor :print_enabled do
      true
    end

    # Set a service to generate a timestamp on each vote. The
    # attribute is the name of a class whose instances are
    # initialized with a string containing the data to be
    # timestamped and respond to a timestamp method
    config_accessor :timestamp_service

    # Set a service to add a signature to pdf of signatures.
    # The attribute is the name of a class whose instances are
    # initialized with the document to be signed and respond to a
    # signed_pdf method with the signature added
    config_accessor :pdf_signature_service

    # This flag allows creating authorizations to unauthorized users.
    config_accessor :do_not_require_authorization do
      false
    end

    # How to count votes. Possible options:
    # - sync. Count them as they are created.
    # - async. Count them using a delayed job.
    # - batch. Count them using a periodic task, not each time.
    # Batch option is tailored for high level of signatures.
    # Notifications for milestoned, threshold and endorsement will
    # be sent when votes are counted, so using the same mode.
    config_accessor :votes_counting_mode do
      :sync
    end

    # How to count unvotes. Possible options:
    # - sync. Count them as they are destroyed.
    # - async. Count them using a delayed job.
    # No batch option, since a high level of unvotes is unlikely.
    config_accessor :unvotes_counting_mode do
      :sync
    end
  end
end
