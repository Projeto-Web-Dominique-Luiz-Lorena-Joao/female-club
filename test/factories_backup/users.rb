# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    sequence(:email) { |n| "user#{n}@example.com" }
    phone { "11#{Faker::Number.number(digits: 9)}" }
    password { "Password123" }
    password_confirmation { "Password123" }
    items_per_page { 15 }

    trait :admin do
      name { "Administrador" }
      email { "admin@femaleclub.com" }
    end

    trait :with_many_items_per_page do
      items_per_page { 50 }
    end

    trait :locked do
      locked_at { Time.current }
    end
  end
end
