# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # Bloquear cadastro direto - redireciona para solicitação de acesso
  def new
    redirect_to new_access_request_path
  end

  def create
    redirect_to new_access_request_path
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:items_per_page])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :items_per_page])
  end
end
