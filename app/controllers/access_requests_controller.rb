# frozen_string_literal: true

class AccessRequestsController < ApplicationController
  skip_before_action :authenticate_user!
  layout "devise"

  def new
    @access_request = AccessRequest.new
  end

  def create
    @access_request = AccessRequest.new(access_request_params)

    if @access_request.save
      redirect_to new_user_session_path, notice: "Solicitação enviada com sucesso! Aguarde a aprovação do administrador."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def access_request_params
    params.require(:access_request).permit(:email, :password, :password_confirmation, :message)
  end
end
