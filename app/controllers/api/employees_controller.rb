class Api::EmployeesController < ApplicationController
  def search
    @employees = Employee.where("full_name ILIKE ?", "%#{params[:q]}%")
                        .limit(10)
                        .order(:full_name)

    render json: @employees.map { |e| { id: e.id, name: e.full_name } }
  end
end
