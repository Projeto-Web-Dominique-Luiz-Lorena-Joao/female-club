# frozen_string_literal: true

FactoryBot.define do
  factory :sale_service do
    association :sale
    association :service
    quantity { 1 }
    unit_price { 80.00 }

    trait :multiple_sessions do
      quantity { 3 }
    end

    trait :single_session do
      quantity { 1 }
    end

    trait :expensive do
      unit_price { 300.00 }
    end

    trait :cheap do
      unit_price { 30.00 }
    end
  end
end
