# frozen_string_literal: true

FactoryBot.define do
  factory :stock_movement do
    association :product
    association :employee
    association :sale, factory: :sale
    quantity { 5 }
    movement_type { :venda }
    description { nil }

    trait :aquisicao do
      movement_type { :aquisicao }
      sale { nil }
    end

    trait :venda do
      movement_type { :venda }
    end

    trait :perda do
      movement_type { :perda_extravio }
      sale { nil }
    end

    trait :devolucao do
      movement_type { :devolucao }
    end

    trait :ajuste do
      movement_type { :ajuste_estoque }
      sale { nil }
    end

    trait :cancelamento do
      movement_type { :cancellation_return }
    end

    trait :without_sale do
      sale { nil }
    end

    trait :with_description do
      description { "Movimentação de estoque registrada" }
    end
  end
end
