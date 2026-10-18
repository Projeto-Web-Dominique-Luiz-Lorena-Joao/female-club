class Users::PasswordsController < Devise::PasswordsController
  protected

  # Redirecionar para a tela de login após enviar instruções de recuperação
  def after_sending_reset_password_instructions_path_for(resource_name)
    new_session_path(resource_name)
  end

  # Redirecionar para o dashboard após redefinir a senha com sucesso
  def after_resetting_password_path_for(resource)
    authenticated_root_path
  end
end
