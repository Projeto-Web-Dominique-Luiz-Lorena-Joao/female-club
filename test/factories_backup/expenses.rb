# frozen_string_literal: true

FactoryBot.define do
  factory :expense do
    association :employee
    association :supplier
    expense_date { Date.current }
    expense_type { :supplies }
    amount { Faker::Commerce.price(range: 50.0..1000.0) }
    payment_method { :pix }
    category { :esporadica }
    status { :ativa }
    notes { nil }

    # Tipos de despesa
    trait :aluguel do
      expense_type { :aluguel }
      category { :fixa_mensal }
      amount { 2500.00 }
    end

    trait :utilities do
      expense_type { :utilities }
      category { :fixa_mensal }
    end

    trait :salaries do
      expense_type { :salaries }
      category { :fixa_mensal }
    end

    trait :supplies do
      expense_type { :supplies }
      category { :esporadica }
    end

    trait :maintenance do
      expense_type { :maintenance }
      category { :esporadica }
    end

    trait :marketing do
      expense_type { :marketing }
      category { :esporadica }
    end

    # Categorias
    trait :fixa_mensal do
      category { :fixa_mensal }
    end

    trait :fixa_anual do
      category { :fixa_anual }
    end

    trait :esporadica do
      category { :esporadica }
    end

    trait :rara do
      category { :rara }
    end

    # Métodos de pagamento
    trait :dinheiro do
      payment_method { :dinheiro }
    end

    trait :cartao do
      payment_method { :cartao_credito }
    end

    trait :pix do
      payment_method { :pix }
    end

    trait :boleto do
      payment_method { :boleto }
    end

    # Status
    trait :ativa do
      status { :ativa }
    end

    trait :inativa do
      status { :inativa }
    end

    # Outros
    trait :without_supplier do
      supplier { nil }
    end

    trait :with_notes do
      notes { "Despesa registrada conforme nota fiscal" }
    end

    trait :high_value do
      amount { 5000.00 }
    end

    trait :low_value do
      amount { 25.00 }
    end
  end
end
