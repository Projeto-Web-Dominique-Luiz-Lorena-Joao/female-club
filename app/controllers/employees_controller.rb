class EmployeesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee, only: [:show, :edit, :update, :destroy]

  def index
    @employees = Employee.all.order(created_at: :desc)


    if params[:status].present?
      @employees = @employees.where(status: params[:status])
    end


    if params[:position].present?
      @employees = @employees.by_position(params[:position])
    end


    if params[:search].present?
      @employees = @employees.where('full_name ILIKE ? OR cpf ILIKE ?',
                                   "%#{params[:search]}%",
                                   "%#{params[:search]}%")
    end


    @total_employees = @employees.count
    @active_employees = Employee.active.count
    @total_salary = Employee.active.sum(:salary)
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