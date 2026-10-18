# frozen_string_literal: true

class Admin::UsersController < ApplicationController
  before_action :require_admin!
  before_action :set_user, only: %i[deactivate reactivate]

  def index
    @users = User.order(created_at: :desc)
    @users = @users.where(active: params[:status] == "active") if params[:status].present? && params[:status] != "all"
    @users = @users.page(params[:page]).per(per_page)
    @total_users = User.count
    @active_users = User.active.count
    @inactive_users = User.inactive.count
  end

  def deactivate
    if @user == current_user
      redirect_to admin_users_path, alert: "Você não pode cancelar sua própria conta."
      return
    end

    if @user.admin?
      redirect_to admin_users_path, alert: "Não é possível cancelar a conta de outro administrador."
      return
    end

    @user.update!(active: false)
    redirect_to admin_users_path, notice: "Conta de #{@user.display_name} cancelada com sucesso."
  end

  def reactivate
    @user.update!(active: true)
    redirect_to admin_users_path, notice: "Conta de #{@user.display_name} reativada com sucesso."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def require_admin!
    unless current_user.admin?
      redirect_to dashboard_path, alert: "Acesso restrito a administradores."
    end
  end
end
