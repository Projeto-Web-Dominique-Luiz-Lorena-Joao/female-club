# frozen_string_literal: true

FactoryBot.define do
  factory :product_input do
    association :product
    association :supplier
    association :created_by, factory: :user
    quantity { 50 }
    unit_cost { Faker::Commerce.price(range: 5.0..100.0) }
    date_input { Date.current }
    invoice_number { "NF-#{Faker::Number.number(digits: 6)}" }
    notes { nil }

    trait :small_quantity do
      quantity { 10 }
    end

    trait :large_quantity do
      quantity { 500 }
    end

    trait :expensive do
      unit_cost { 150.00 }
    end

    trait :cheap do
      unit_cost { 5.00 }
    end

    trait :with_notes do
      notes { "Reposição de estoque" }
    end

    trait :recent do
      date_input { Date.current }
    end

    trait :old do
      date_input { 6.months.ago.to_date }
    end

    trait :without_supplier do
      supplier { nil }
    end

    trait :without_invoice do
      invoice_number { nil }
    end
  end
end
