# frozen_string_literal: true

FactoryBot.define do
  factory :product_output do
    association :product
    association :created_by, factory: :user
    quantity { 5 }
    output_type { :perda }
    date_output { Date.current }
    notes { nil }

    trait :venda do
      output_type { :venda }
    end

    trait :perda do
      output_type { :perda }
    end

    trait :extravio do
      output_type { :extravio }
    end

    trait :dano do
      output_type { :dano }
    end

    trait :devolucao do
      output_type { :devolucao }
    end

    trait :small_quantity do
      quantity { 1 }
    end

    trait :large_quantity do
      quantity { 50 }
    end

    trait :with_notes do
      notes { "Produto danificado durante transporte" }
    end

    trait :recent do
      date_output { Date.current }
    end

    trait :old do
      date_output { 3.months.ago.to_date }
    end
  end
end
