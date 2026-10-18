# frozen_string_literal: true

FactoryBot.define do
  factory :employee do
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
    position { :cabeleireira }
    phone { "11#{Faker::Number.number(digits: 9)}" }
    sequence(:email) { |n| "employee#{n}@femaleclub.com" }
    address { Faker::Address.full_address }
    admission_date { 1.year.ago.to_date }
    salary { Faker::Number.decimal(l_digits: 4, r_digits: 2) }
    work_days { "Segunda a Sexta" }
    status { :ativo }

    trait :cabeleireira do
      position { :cabeleireira }
    end

    trait :manicure do
      position { :manicure }
    end

    trait :gerente do
      position { :gerente }
    end

    trait :inativo do
      status { :inativo }
    end

    trait :de_ferias do
      status { :ferias }
    end

    trait :afastado do
      status { :afastado }
    end

    trait :veterano do
      admission_date { 5.years.ago.to_date }
    end

    trait :novato do
      admission_date { 1.month.ago.to_date }
    end
  end
end
