# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sales', type: :request do
  let(:user) { create(:user) }
  let(:customer) { create(:customer) }
  let(:employee) { create(:employee, status: 'ativo') }

  before { login_as(user, scope: :user) }

  describe 'GET /sales' do
    before do
      create_list(:sale, 3, customer: customer, employee: employee)
    end

    it 'returns success' do
      get sales_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the sales list' do
      get sales_path
      expect(response.body).to include('Vendas')
    end

    context 'with status filter' do
      before do
        create(:sale, :pendente, customer: customer, employee: employee)
        create(:sale, :pago, customer: customer, employee: employee)
      end

      it 'filters by status' do
        get sales_path, params: { status: 'pendente' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with payment_method filter' do
      before do
        create(:sale, :dinheiro, customer: customer, employee: employee)
        create(:sale, :pix, customer: customer, employee: employee)
      end

      it 'filters by payment method' do
        get sales_path, params: { payment_method: 'dinheiro' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with customer_id filter' do
      it 'filters by customer' do
        get sales_path, params: { customer_id: customer.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with employee_id filter' do
      it 'filters by employee' do
        get sales_path, params: { employee_id: employee.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with date range filter' do
      it 'filters by date range' do
        get sales_path, params: { start_date: 1.week.ago.to_date, end_date: Date.today }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with sort options' do
      it 'sorts by amount ascending' do
        get sales_path, params: { sort_amount: 'asc' }
        expect(response).to have_http_status(:success)
      end

      it 'sorts by amount descending' do
        get sales_path, params: { sort_amount: 'desc' }
        expect(response).to have_http_status(:success)
      end

      it 'sorts by discounted amount ascending' do
        get sales_path, params: { sort_discounted_amount: 'asc' }
        expect(response).to have_http_status(:success)
      end

      it 'sorts by discounted amount descending' do
        get sales_path, params: { sort_discounted_amount: 'desc' }
        expect(response).to have_http_status(:success)
      end

      it 'sorts by discount ascending' do
        get sales_path, params: { sort_discount: 'asc' }
        expect(response).to have_http_status(:success)
      end

      it 'sorts by discount descending' do
        get sales_path, params: { sort_discount: 'desc' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get sales_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /sales/:id' do
    let(:sale) { create(:sale, customer: customer, employee: employee) }

    it 'returns success' do
      get sale_path(sale)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get sale_path(sale)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /sales/new' do
    it 'returns success' do
      get new_sale_path
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get new_sale_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /sales' do
    let(:valid_attributes) do
      {
        customer_id: customer.id,
        employee_id: employee.id,
        sale_date: Date.today,
        total_amount: 150.00,
        payment_method: 'pix',
        status: 'pago'
      }
    end

    context 'with valid parameters' do
      it 'creates a new sale' do
        expect {
          post sales_path, params: { sale: valid_attributes }
        }.to change(Sale, :count).by(1)
      end

      it 'redirects to the created sale' do
        post sales_path, params: { sale: valid_attributes }
        expect(response).to redirect_to(Sale.last)
      end
    end

    context 'with customer_search instead of customer_id' do
      it 'creates a new customer when customer_search is provided' do
        # Ensure customer is already created before counting
        customer
        employee

        expect {
          post sales_path, params: {
            sale: {
              employee_id: employee.id,
              sale_date: Date.today,
              total_amount: 150.00,
              payment_method: 'pix',
              status: 'pago',
              customer_id: ''
            },
            customer_search: 'Nova Cliente Teste'
          }
        }.to change(Customer, :count).by(1)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { valid_attributes.merge(total_amount: nil) }

      it 'does not create a new sale' do
        expect {
          post sales_path, params: { sale: invalid_attributes }
        }.not_to change(Sale, :count)
      end

      it 'returns unprocessable_entity' do
        post sales_path, params: { sale: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with nested sale_products_attributes' do
      let(:product) { create(:product, :with_stock, initial_stock: 100) }

      it 'creates sale with products' do
        attributes = valid_attributes.merge(
          sale_products_attributes: [
            { product_id: product.id, quantity: 2, unit_price: 50.00 }
          ]
        )

        expect {
          post sales_path, params: { sale: attributes }
        }.to change(Sale, :count).by(1)

        expect(Sale.last.sale_products.count).to eq(1)
      end

      it 'filters out empty sale_products' do
        attributes = valid_attributes.merge(
          sale_products_attributes: [
            { product_id: '', quantity: '', unit_price: '' }
          ]
        )

        post sales_path, params: { sale: attributes }
        expect(response).to redirect_to(Sale.last)
        expect(Sale.last.sale_products.count).to eq(0)
      end
    end

    context 'with nested sale_services_attributes' do
      let(:service) { create(:service) }

      it 'creates sale with services' do
        attributes = valid_attributes.merge(
          sale_services_attributes: [
            { service_id: service.id, quantity: 1, unit_price: 75.00 }
          ]
        )

        expect {
          post sales_path, params: { sale: attributes }
        }.to change(Sale, :count).by(1)

        expect(Sale.last.sale_services.count).to eq(1)
      end

      it 'filters out empty sale_services' do
        attributes = valid_attributes.merge(
          sale_services_attributes: [
            { service_id: '', quantity: '', unit_price: '' }
          ]
        )

        post sales_path, params: { sale: attributes }
        expect(response).to redirect_to(Sale.last)
        expect(Sale.last.sale_services.count).to eq(0)
      end
    end

    context 'with nested attributes in array format (JSON submission)' do
      let(:product) { create(:product, :with_stock, initial_stock: 100) }
      let(:service) { create(:service) }

      it 'handles array format for sale_products_attributes' do
        # Simulating JSON array format
        attributes = valid_attributes.dup
        attributes[:sale_products_attributes] = [
          { product_id: product.id, quantity: 2, unit_price: 50.00 },
          { product_id: '', quantity: '', unit_price: '', _destroy: '1' }
        ]

        post sales_path, params: { sale: attributes }
        expect(response).to redirect_to(Sale.last)
      end

      it 'handles array format for sale_services_attributes' do
        # Simulating JSON array format
        attributes = valid_attributes.dup
        attributes[:sale_services_attributes] = [
          { service_id: service.id, quantity: 1, unit_price: 75.00 },
          { service_id: '', quantity: '', unit_price: '', _destroy: '1' }
        ]

        post sales_path, params: { sale: attributes }
        expect(response).to redirect_to(Sale.last)
      end
    end

    context 'with nested attributes in hash format (form submission)' do
      let(:product) { create(:product, :with_stock, initial_stock: 100) }
      let(:service) { create(:service) }

      it 'handles hash format for sale_products_attributes' do
        # Simulating traditional form submission format (Hash with indices)
        attributes = valid_attributes.dup
        attributes[:sale_products_attributes] = {
          '0' => { product_id: product.id, quantity: 2, unit_price: 50.00 },
          '1' => { product_id: '', quantity: '', unit_price: '' }
        }

        post sales_path, params: { sale: attributes }
        expect(response).to redirect_to(Sale.last)
        expect(Sale.last.sale_products.count).to eq(1)
      end

      it 'handles hash format for sale_services_attributes' do
        # Simulating traditional form submission format (Hash with indices)
        attributes = valid_attributes.dup
        attributes[:sale_services_attributes] = {
          '0' => { service_id: service.id, quantity: 1, unit_price: 75.00 },
          '1' => { service_id: '', quantity: '', unit_price: '' }
        }

        post sales_path, params: { sale: attributes }
        expect(response).to redirect_to(Sale.last)
        expect(Sale.last.sale_services.count).to eq(1)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        post sales_path, params: { sale: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /sales/:id/edit' do
    let(:sale) { create(:sale, customer: customer, employee: employee) }

    it 'returns success' do
      get edit_sale_path(sale)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get edit_sale_path(sale)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /sales/:id' do
    let(:sale) { create(:sale, customer: customer, employee: employee, total_amount: 100.00) }

    context 'with valid parameters' do
      it 'updates the sale' do
        patch sale_path(sale), params: { sale: { total_amount: 200.00 } }
        sale.reload
        expect(sale.total_amount).to eq(200.00)
      end

      it 'redirects to the sale' do
        patch sale_path(sale), params: { sale: { total_amount: 200.00 } }
        expect(response).to redirect_to(sale)
      end
    end

    context 'with customer_search instead of customer_id' do
      it 'creates a new customer when customer_search is provided' do
        # Ensure sale is already created before counting
        sale

        expect {
          patch sale_path(sale), params: {
            sale: { customer_id: '' },
            customer_search: 'Novo Cliente Atualização'
          }
        }.to change(Customer, :count).by(1)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable_entity' do
        patch sale_path(sale), params: { sale: { total_amount: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with nested attributes in array format' do
      let(:product) { create(:product, :with_stock, initial_stock: 100) }
      let(:service) { create(:service) }

      it 'handles array format for sale_products on update' do
        patch sale_path(sale), params: {
          sale: {
            total_amount: 250.00,
            sale_products_attributes: [
              { product_id: product.id, quantity: 2, unit_price: 50.00 },
              { product_id: '', quantity: '', unit_price: '', _destroy: '1' }
            ]
          }
        }
        expect(response).to redirect_to(sale)
      end

      it 'handles array format for sale_services on update' do
        patch sale_path(sale), params: {
          sale: {
            total_amount: 250.00,
            sale_services_attributes: [
              { service_id: service.id, quantity: 1, unit_price: 75.00 },
              { service_id: '', quantity: '', unit_price: '', _destroy: '1' }
            ]
          }
        }
        expect(response).to redirect_to(sale)
      end
    end

    context 'with nested attributes in hash format (form submission) on update' do
      let(:product) { create(:product, :with_stock, initial_stock: 100) }
      let(:service) { create(:service) }

      it 'handles hash format for sale_products_attributes on update' do
        patch sale_path(sale), params: {
          sale: {
            total_amount: 250.00,
            sale_products_attributes: {
              '0' => { product_id: product.id, quantity: 2, unit_price: 50.00 },
              '1' => { product_id: '', quantity: '', unit_price: '' }
            }
          }
        }
        expect(response).to redirect_to(sale)
      end

      it 'handles hash format for sale_services_attributes on update' do
        patch sale_path(sale), params: {
          sale: {
            total_amount: 250.00,
            sale_services_attributes: {
              '0' => { service_id: service.id, quantity: 1, unit_price: 75.00 },
              '1' => { service_id: '', quantity: '', unit_price: '' }
            }
          }
        }
        expect(response).to redirect_to(sale)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch sale_path(sale), params: { sale: { total_amount: 200.00 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /sales/:id/mark_as_paid' do
    let(:sale) { create(:sale, :pendente, customer: customer, employee: employee) }

    it 'marks the sale as paid' do
      patch mark_as_paid_sale_path(sale)
      sale.reload
      expect(sale.status).to eq('pago')
    end

    it 'redirects to the sale' do
      patch mark_as_paid_sale_path(sale)
      expect(response).to redirect_to(sale)
    end

    it 'shows success notice' do
      patch mark_as_paid_sale_path(sale)
      expect(flash[:notice]).to eq('Venda marcada como paga.')
    end

    context 'when already paid' do
      let(:paid_sale) { create(:sale, :pago, customer: customer, employee: employee) }

      it 'still redirects to the sale' do
        patch mark_as_paid_sale_path(paid_sale)
        expect(response).to redirect_to(paid_sale)
      end
    end

    context 'when mark_as_paid fails' do
      let(:sale_with_error) { create(:sale, :pendente, customer: customer, employee: employee) }

      it 'shows an alert message' do
        allow_any_instance_of(Sale).to receive(:mark_as_paid!).and_return(false)
        patch mark_as_paid_sale_path(sale_with_error)
        expect(flash[:alert]).to eq('Erro ao marcar venda como paga.')
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch mark_as_paid_sale_path(sale)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /sales/search_employees' do
    before do
      create(:employee, full_name: 'Maria Silva', status: 'ativo')
      create(:employee, full_name: 'Ana Santos', status: 'ativo')
      create(:employee, full_name: 'Joana Costa', status: 'inativo')
    end

    it 'returns matching employees as JSON' do
      get search_employees_sales_path, params: { query: 'Maria' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Maria Silva')
    end

    it 'only returns active employees' do
      get search_employees_sales_path, params: { query: 'Costa' }
      json = JSON.parse(response.body)
      expect(json.length).to eq(0)
    end

    it 'limits results to 10' do
      15.times do |i|
        create(:employee, status: 'ativo', full_name: "Test Employee #{i}")
      end
      get search_employees_sales_path, params: { query: 'Test' }
      json = JSON.parse(response.body)
      expect(json.length).to be <= 10
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get search_employees_sales_path, params: { query: 'Maria' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /sales/search_customers' do
    before do
      create(:customer, full_name: 'Carla Oliveira')
      create(:customer, full_name: 'Paula Souza')
    end

    it 'returns matching customers as JSON' do
      get search_customers_sales_path, params: { query: 'Carla' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Carla Oliveira')
    end

    it 'limits results to 10' do
      create_list(:customer, 15, full_name: 'Test Customer')
      get search_customers_sales_path, params: { query: 'Test' }
      json = JSON.parse(response.body)
      expect(json.length).to be <= 10
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get search_customers_sales_path, params: { query: 'Carla' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /sales/search_products' do
    before do
      create(:product, name: 'Shampoo Profissional', code: 'SH001', active: true)
      create(:product, name: 'Condicionador', code: 'CD001', active: true)
      create(:product, name: 'Produto Inativo', active: false)
    end

    it 'returns matching products by name as JSON' do
      get search_products_sales_path, params: { query: 'Shampoo' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Shampoo Profissional')
    end

    it 'returns matching products by code as JSON' do
      get search_products_sales_path, params: { query: 'CD001' }
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Condicionador')
    end

    it 'only returns active products' do
      get search_products_sales_path, params: { query: 'Inativo' }
      json = JSON.parse(response.body)
      expect(json.length).to eq(0)
    end

    it 'includes price in response' do
      get search_products_sales_path, params: { query: 'Shampoo' }
      json = JSON.parse(response.body)
      expect(json.first).to have_key('price')
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get search_products_sales_path, params: { query: 'Shampoo' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /sales/search_services' do
    before do
      create(:service, name: 'Corte de Cabelo', active: 'ativo')
      create(:service, name: 'Manicure', active: 'ativo')
      create(:service, name: 'Serviço Inativo', active: 'inativo')
    end

    it 'returns matching services as JSON' do
      get search_services_sales_path, params: { query: 'Corte' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Corte de Cabelo')
    end

    it 'only returns active services' do
      get search_services_sales_path, params: { query: 'Inativo' }
      json = JSON.parse(response.body)
      expect(json.length).to eq(0)
    end

    it 'includes price in response' do
      get search_services_sales_path, params: { query: 'Manicure' }
      json = JSON.parse(response.body)
      expect(json.first).to have_key('price')
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get search_services_sales_path, params: { query: 'Corte' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
