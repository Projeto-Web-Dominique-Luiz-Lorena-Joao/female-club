class ServicesController < ApplicationController
  before_action :set_service, only: [:show, :edit, :update, :destroy, :change_status]

  # GET /services
  def index
    @services = Service.ordered_by_name

    # Filtro por status (opcional)
    if params[:active].present? && Service.actives.key?(params[:active])
      @services = @services.where(active: params[:active])
    end

    @services = @services.page(params[:page]).per(15)
  end

  # GET /services/:id
  def show
    @sale_services = @service.sale_services.includes(:sale)
    #@service_appointments = @service.service_appointments.includes(:employee, :customer)
  end

  # GET /services/new
  def new
    @service = Service.new
  end

  # POST /services
  def create
    @service = Service.new(service_params)

    if @service.save
      redirect_to @service, notice: 'Serviço criado com sucesso!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /services/:id/edit
  def edit
  end

  # PATCH/PUT /services/:id
  def update
    if @service.update(service_params)
      redirect_to @service, notice: 'Serviço atualizado com sucesso!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /services/:id
  def destroy
    if @service.destroy
      redirect_to services_url, notice: 'Serviço excluído com sucesso!'
    else
      redirect_to services_url, alert: 'Erro ao excluir serviço. Verifique se não há registros relacionados.'
    end
  end

  # PATCH /services/:id/change_status
  def change_status
    new_active = params[:new_active]

    if Service.actives.key?(new_active) && @service.update(active: new_active)
      redirect_to services_url, notice: "Status atualizado para #{@service.status_label}!"
    else
      redirect_to services_url, alert: 'Erro ao atualizar status.'
    end
  end

  private

  def set_service
    @service = Service.find(params[:id])
  end

  def service_params
    params.require(:service).permit(:name, :description, :price, :active)
  end
end