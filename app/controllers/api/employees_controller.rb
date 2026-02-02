class Api::EmployeesController < ApplicationController
  def search
    query = sanitize_search(params[:q], max_length: 50)
    @employees = Employee.where("full_name ILIKE ?", "%#{query}%")
                        .limit(10)
                        .order(:full_name)

    render json: @employees.map { |e| { id: e.id, name: e.full_name } }
  end
end
