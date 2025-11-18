class EmployeesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee, only: [:show, :edit, :update, :destroy]

  def index
    @employees = Employee.all

    if params[:status].present?
      @employees = @employees.where(status: params[:status])
    end

    if params[:position].present?
      @employees = @employees.by_position(params[:position])
    end

    if params[:search].present?
      search_term = params[:search].strip
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
        # Mais antigos primeiro (admission_date mais antiga = maior)
        @employees = @employees.order(admission_date: :asc, created_at: :desc)
      when 'asc'
        # Mais novos primeiro (admission_date mais recente = menor)
        @employees = @employees.order(admission_date: :desc, created_at: :desc)
      end
    else
      # Ordenação padrão
      @employees = @employees.order(created_at: :desc)
    end

    @total_employees = @employees.count
    @active_employees = Employee.where(status: ['ativo', 'ferias']).count
    @total_salary = Employee.where(status: ['ativo', 'ferias']).sum(:salary)
  end

  def show
    # @recent_sales = @employee.sales.recent.limit(5)
    # @recent_movements = @employee.stock_movements.recent.limit(5)
  end

  def new
    @employee = Employee.new
  end

  def edit
  end

  def create
    @employee = Employee.new(employee_params)

    if @employee.save
      redirect_to employees_path, notice: 'Funcionário cadastrado com sucesso!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @employee.update(employee_params)
      redirect_to employees_path, notice: 'Funcionário atualizado com sucesso!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @employee.destroy
    redirect_to employees_path, notice: 'Funcionário excluído com sucesso!'
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(
      :full_name, :cpf, :position, :phone, :email,
      :address, :admission_date, :salary, :work_days,
      :notes, :status
    )
  end
end