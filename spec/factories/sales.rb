# frozen_string_literal: true

FactoryBot.define do
  factory :sale do
    association :customer
    association :employee
    sale_date { Date.current }
    total_amount { 100.00 }
    payment_method { :pix }
    status { :pago }
    discount_percentage { 0 }
    notes { nil }

    trait :pendente do
      status { :pendente }
    end

    trait :pago do
      status { :pago }
      paid_date { Date.current }
    end

    trait :cancelado do
      status { :cancelado }
    end

    trait :expirado do
      status { :expirado }
    end

    trait :dinheiro do
      payment_method { :dinheiro }
    end

    trait :cartao_credito do
      payment_method { :cartao_credito }
    end

    trait :cartao_debito do
      payment_method { :cartao_debito }
    end

    trait :pix do
      payment_method { :pix }
    end

    trait :boleto do
      payment_method { :boleto }
      due_date { 30.days.from_now.to_date }
    end

    trait :with_discount do
      discount_percentage { 10 }
    end

    trait :big_discount do
      discount_percentage { 25 }
    end

    trait :without_customer do
      customer { nil }
    end

    trait :with_notes do
      notes { "Venda especial" }
    end

    trait :overdue do
      status { :pendente }
      payment_method { :boleto }
      due_date { 10.days.ago.to_date }
    end

    # Trait para criar venda com produtos
    trait :with_products do
      transient do
        products_count { 2 }
      end

      after(:create) do |sale, evaluator|
        evaluator.products_count.times do
          product = create(:product, :with_stock, initial_stock: 100)
          create(:sale_product, sale: sale, product: product, quantity: 1, unit_price: product.sale_price)
        end
        sale.reload
        sale.update(total_amount: sale.sale_products.sum { |sp| sp.quantity * sp.unit_price })
      end
    end

    # Trait para criar venda com serviços
    trait :with_services do
      transient do
        services_count { 2 }
      end

      after(:create) do |sale, evaluator|
        evaluator.services_count.times do
          service = create(:service)
          create(:sale_service, sale: sale, service: service, quantity: 1, unit_price: service.price)
        end
        sale.reload
        sale.update(total_amount: sale.sale_services.sum { |ss| ss.quantity * ss.unit_price })
      end
    end
  end
end
