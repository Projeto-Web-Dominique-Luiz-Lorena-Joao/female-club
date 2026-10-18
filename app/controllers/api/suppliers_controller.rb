class Api::SuppliersController < ApplicationController
  def search
    query = sanitize_search(params[:q], max_length: 50)
    @suppliers = Supplier.where("legal_name ILIKE ? OR trade_name ILIKE ?",
                               "%#{query}%", "%#{query}%")
                        .limit(10)
                        .order(:legal_name)

    render json: @suppliers.map { |s| { id: s.id, name: s.display_name } }
  end
end
