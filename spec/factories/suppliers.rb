# frozen_string_literal: true

FactoryBot.define do
  factory :supplier do
    legal_name { Faker::Company.name }
    trade_name { Faker::Company.name }
    phone_number { "11#{Faker::Number.number(digits: 9)}" }
    sequence(:email) { |n| "supplier#{n}@example.com" }
    full_address { Faker::Address.full_address }
    product_category { :cosmeticos }
    status { :ativo }

    trait :cosmeticos do
      product_category { :cosmeticos }
    end

    trait :maquiagem do
      product_category { :maquiagem }
    end

    trait :cabelo do
      product_category { :cabelo }
    end

    trait :equipamentos do
      product_category { :equipamentos }
    end

    trait :inativo do
      status { :inativo }
    end

    trait :without_email do
      email { nil }
    end
  end
end
