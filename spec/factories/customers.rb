# frozen_string_literal: true

FactoryBot.define do
  factory :customer do
    full_name { Faker::Name.name }
    transient do
      cpf_generator do
        cpf = Array.new(9) { rand(0..9) }
        sum = cpf.each_with_index.sum { |d, i| d * (10 - i) }
        cpf << (sum % 11 < 2 ? 0 : 11 - sum % 11)
        sum = cpf.each_with_index.sum { |d, i| d * (11 - i) }
        cpf << (sum % 11 < 2 ? 0 : 11 - sum % 11)
        cpf.join
      end
    end
    cpf { cpf_generator }
    birth_date { Faker::Date.birthday(min_age: 18, max_age: 80) }
    phone_number { "11#{Faker::Number.number(digits: 9)}" }
    sequence(:email) { |n| "customer#{n}@example.com" }
    full_address { Faker::Address.full_address }
    notes { nil }
    guarantor { nil }

    trait :with_guarantor do
      association :guarantor
    end

    trait :vip do
      notes { "Cliente VIP" }
    end

    trait :morning_preference do
      notes { "Prefere atendimento pela manhã" }
    end

    trait :without_email do
      email { nil }
    end

    trait :minor do
      birth_date { 15.years.ago.to_date }
    end

    trait :senior do
      birth_date { 70.years.ago.to_date }
    end
  end
end
