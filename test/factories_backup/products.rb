# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Produto #{n}" }
    brand { Faker::Company.name }
    category { :beleza_cosmeticos }
    color { Faker::Color.color_name }
    sale_price { Faker::Commerce.price(range: 10.0..500.0) }
    min_stock { 10 }
    unit { "unidade" }
    location { "Prateleira A1" }
    description { Faker::Lorem.sentence }
    association :supplier

    trait :beleza do
      category { :beleza_cosmeticos }
    end

    trait :moda do
      category { :moda_acessorios }
    end

    trait :fitness do
      category { :fitness_esportes }
    end

    trait :expensive do
      sale_price { 999.99 }
    end

    trait :cheap do
      sale_price { 9.99 }
    end

    trait :high_min_stock do
      min_stock { 50 }
    end

    trait :low_min_stock do
      min_stock { 5 }
    end

    trait :without_supplier do
      supplier { nil }
    end

    # Trait para criar produto já com estoque
    trait :with_stock do
      transient do
        initial_stock { 100 }
      end

      after(:create) do |product, evaluator|
        create(:product_input, product: product, quantity: evaluator.initial_stock)
        product.reload
      end
    end

    trait :out_of_stock do
      after(:create) do |product|
        # Não cria nenhum input, então estoque = 0
        product.update_stock_status!
      end
    end

    trait :critical_stock do
      transient do
        stock_quantity { 5 }
      end
      min_stock { 10 }

      after(:create) do |product, evaluator|
        create(:product_input, product: product, quantity: evaluator.stock_quantity)
        product.reload
      end
    end

    trait :low_stock do
      transient do
        stock_quantity { 15 }
      end
      min_stock { 10 }

      after(:create) do |product, evaluator|
        create(:product_input, product: product, quantity: evaluator.stock_quantity)
        product.reload
      end
    end
  end
end
