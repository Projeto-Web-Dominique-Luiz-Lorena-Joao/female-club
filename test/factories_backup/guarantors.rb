# frozen_string_literal: true

FactoryBot.define do
  factory :guarantor do
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
    phone { "11#{Faker::Number.number(digits: 9)}" }
    address { Faker::Address.full_address }
    relationship { :pai }
    status { :ativo }

    trait :pai do
      relationship { :pai }
    end

    trait :mae do
      relationship { :mae }
    end

    trait :esposo do
      relationship { :esposo }
    end

    trait :amigo do
      relationship { :amigo }
    end

    trait :inativo do
      status { :inativo }
    end

    trait :without_cpf do
      cpf { nil }
    end

    trait :without_phone do
      phone { nil }
    end
  end
end
