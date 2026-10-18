# frozen_string_literal: true

FactoryBot.define do
  factory :access_request do
    email { Faker::Internet.email }
    password { 'Password123!' }
    password_confirmation { 'Password123!' }
    message { 'Gostaria de acessar o sistema para gerenciar vendas.' }
    status { 'pending' }

    trait :approved do
      status { 'approved' }
    end

    trait :rejected do
      status { 'rejected' }
    end
  end
end
