# frozen_string_literal: true

class Admin::AccessRequestsController < ApplicationController
  before_action :set_access_request, only: %i[approve reject]

  def index
    @access_requests = AccessRequest.recent
    @access_requests = @access_requests.where(status: params[:status]) if params[:status].present?
    @access_requests = @access_requests.page(params[:page]).per(per_page)
    @pending_count = AccessRequest.pending.count
  end

  def approve
    if User.exists?(email: @access_request.email)
      redirect_to admin_access_requests_path, alert: "Já existe um usuário com este e-mail."
      return
    end

    user = User.new(
      email: @access_request.email,
      encrypted_password: @access_request.encrypted_password
    )
    user.save(validate: false)

    @access_request.update!(status: "approved")
    redirect_to admin_access_requests_path, notice: "Solicitação aprovada! Usuário criado com sucesso."
  end

  def reject
    @access_request.update!(status: "rejected")
    redirect_to admin_access_requests_path, notice: "Solicitação rejeitada."
  end

  private

  def set_access_request
    @access_request = AccessRequest.find(params[:id])
  end
end
