# frozen_string_literal: true

FactoryBot.define do
  factory :service do
    sequence(:name) { |n| "Serviço #{n}" }
    description { Faker::Lorem.paragraph }
    price { Faker::Commerce.price(range: 30.0..300.0) }
    active { :ativo }

    trait :ativo do
      active { :ativo }
    end

    trait :inativo do
      active { :inativo }
    end

    trait :arquivado do
      active { :arquivado }
    end

    trait :corte_cabelo do
      name { "Corte de Cabelo Feminino" }
      price { 78.90 }
    end

    trait :manicure do
      name { "Manicure (Mão)" }
      price { 35.94 }
    end

    trait :depilacao do
      name { "Depilação Perna Completa" }
      price { 62.90 }
    end

    trait :expensive do
      price { 500.00 }
    end

    trait :cheap do
      price { 15.00 }
    end
  end
end
