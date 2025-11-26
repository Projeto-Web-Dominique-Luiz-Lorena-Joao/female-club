class Api::SuppliersController < ApplicationController
  def search
    @suppliers = Supplier.where("legal_name ILIKE ? OR trade_name ILIKE ?",
                               "%#{params[:q]}%", "%#{params[:q]}%")
                        .limit(10)
                        .order(:legal_name)

    render json: @suppliers.map { |s| { id: s.id, name: s.display_name } }
  end
end
