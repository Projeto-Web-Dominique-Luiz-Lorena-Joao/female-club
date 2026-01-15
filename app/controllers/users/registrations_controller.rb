class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  protected

  # Permite parâmetros adicionais no sign up
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:items_per_page])
  end

  # Permite parâmetros adicionais no update de conta
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:items_per_page])
  end
end
