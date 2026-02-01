# frozen_string_literal: true

FactoryBot.define do
  factory :sale_product do
    association :sale
    association :product
    quantity { 1 }
    unit_price { 50.00 }

    trait :multiple_units do
      quantity { 5 }
    end

    trait :single_unit do
      quantity { 1 }
    end

    trait :expensive do
      unit_price { 200.00 }
    end

    trait :cheap do
      unit_price { 10.00 }
    end
  end
end
