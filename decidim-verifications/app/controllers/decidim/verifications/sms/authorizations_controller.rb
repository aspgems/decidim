# frozen_string_literal: true

module Decidim
  module Verifications
    module Sms
      class AuthorizationsController < ApplicationController
        helper_method :authorization

        def new
          enforce_permission_to :create, :authorization, authorization: authorization

          @form = MobilePhoneForm.new
        end

        def create
          enforce_permission_to :create, :authorization, authorization: authorization

          @form = MobilePhoneForm.from_params(params.merge(user: current_user))

          PerformAuthorizationStep.call(authorization, @form) do
            on(:ok) do
              flash[:notice] = t("authorizations.create.success", scope: "decidim.verifications.sms")
              authorization_method = Decidim::Verifications::Adapter.from_element(authorization.name)
              redirect_to authorization_method.resume_authorization_path
            end
            on(:invalid) do
              flash.now[:alert] = t("authorizations.create.error", scope: "decidim.verifications.sms")
              render :new
            end
          end
        end

        def edit
          enforce_permission_to :update, :authorization, authorization: authorization

          @form = ConfirmationForm.from_params(params)
        end

        def update
          enforce_permission_to :update, :authorization, authorization: authorization

          @form = ConfirmationForm.from_params(params)

          ConfirmUserAuthorization.call(authorization, @form) do
            on(:ok) do
              flash[:notice] = t("authorizations.update.success", scope: "decidim.verifications.sms")
              redirect_to decidim_verifications.authorizations_path
            end

            on(:invalid) do
              flash.now[:alert] = t("authorizations.update.error", scope: "decidim.verifications.sms")
              render :edit
            end
          end
        end

        def destroy
          enforce_permission_to :destroy, :authorization, authorization: authorization

          authorization.destroy!
          flash[:notice] = t("authorizations.destroy.success", scope: "decidim.verifications.sms")

          redirect_to action: :new
        end

        private

        def authorization
          @authorization ||= Decidim::Authorization.find_or_initialize_by(
            user: current_user,
            name: "sms"
          )
        end
      end
    end
  end
end
