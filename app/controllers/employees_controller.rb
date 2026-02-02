class EmployeesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee, only: [:show, :edit, :update, :destroy, :reactivate]

  def index
    @employees = Employee.all

    if params[:status].present?
      @employees = @employees.where(status: params[:status])
    end

    if params[:position].present?
      @employees = @employees.by_position(params[:position])
    end

    if params[:search].present?
      search_term = sanitize_search(params[:search])
      clean_search = search_term.gsub(/\D/, '')

      if clean_search.present?
        @employees = @employees.where(
          'full_name ILIKE ? OR email ILIKE ? OR cpf LIKE ? OR phone LIKE ?',
          "%#{search_term}%",
          "%#{search_term}%",
          "%#{clean_search}%",
          "%#{clean_search}%"
        )
      else
        @employees = @employees.where(
          'full_name ILIKE ? OR email ILIKE ?',
          "%#{search_term}%",
          "%#{search_term}%"
        )
      end
    end

    # Aplicar ordenação
    if params[:sort_admission].present?
      case params[:sort_admission]
      when 'desc'
        @employees = @employees.order(admission_date: :asc, created_at: :desc)
      when 'asc'
        @employees = @employees.order(admission_date: :desc, created_at: :desc)
      end
    else
      @employees = @employees.order(created_at: :desc)
    end

    # PERFORMANCE: Calcular totais em uma única query com subqueries
    @total_employees = @employees.count
    active_stats = Employee.where(status: ['ativo', 'ferias'])
                           .select('COUNT(*) as count, COALESCE(SUM(salary), 0) as total_salary')
                           .take
    @active_employees = active_stats&.count || 0
    @total_salary = active_stats&.total_salary || 0

    @employees = @employees.page(params[:page]).per(per_page)
  end

  def show
  end

  def new
    @employee = Employee.new
  end

  def edit
  end

  def create
    @employee = Employee.new(employee_params.except(:photo_delete))

    if @employee.save
      redirect_to employees_path, notice: 'Funcionário cadastrado com sucesso!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # Remover foto se solicitado
    if params[:employee][:photo_delete] == 'true'
      @employee.photo.purge
    end

    # Remover photo_delete dos params antes de atualizar
    update_params = employee_params.except(:photo_delete)

    if @employee.update(update_params)
      redirect_to employees_path, notice: 'Funcionário atualizado com sucesso!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @employee.update(status: :inativo)
      redirect_to employees_path, notice: 'Funcionário inativado com sucesso!'
    else
      redirect_to employees_path, alert: 'Não foi possível inativar o funcionário.'
    end
  end

  def reactivate
    if @employee.update(status: :ativo)
      redirect_to employee_path(@employee), notice: 'Funcionário reativado com sucesso!'
    else
      redirect_to employee_path(@employee), alert: 'Não foi possível reativar o funcionário.'
    end
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(
      :full_name, :cpf, :position, :phone, :email,
      :address, :admission_date, :salary, :work_days,
      :notes, :status, :photo, :photo_delete
    )
  end
end