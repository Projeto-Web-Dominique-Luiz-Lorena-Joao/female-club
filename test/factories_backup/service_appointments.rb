# frozen_string_literal: true

FactoryBot.define do
  factory :service_appointment do
    association :service
    association :employee
    association :customer
    appointment_date { 1.day.from_now.change(hour: 10, min: 0) }
    duration_minutes { 60 }
    status { :agendado }

    trait :agendado do
      status { :agendado }
    end

    trait :concluido do
      status { :concluido }
    end

    trait :cancelado do
      status { :cancelado }
    end

    trait :nao_compareceu do
      status { :nao_compareceu }
    end

    trait :short_duration do
      duration_minutes { 15 }
    end

    trait :medium_duration do
      duration_minutes { 60 }
    end

    trait :long_duration do
      duration_minutes { 120 }
    end

    trait :very_long_duration do
      duration_minutes { 240 }
    end

    trait :morning do
      appointment_date { 1.day.from_now.change(hour: 9, min: 0) }
    end

    trait :afternoon do
      appointment_date { 1.day.from_now.change(hour: 14, min: 0) }
    end

    trait :evening do
      appointment_date { 1.day.from_now.change(hour: 18, min: 0) }
    end

    trait :tomorrow do
      appointment_date { 1.day.from_now.change(hour: 10, min: 0) }
    end

    trait :next_week do
      appointment_date { 1.week.from_now.change(hour: 10, min: 0) }
    end

    # Para criar agendamento em horário específico
    transient do
      at_hour { nil }
      at_minute { 0 }
      on_date { nil }
    end

    after(:build) do |appointment, evaluator|
      if evaluator.at_hour.present?
        date = evaluator.on_date || 1.day.from_now.to_date
        appointment.appointment_date = date.to_time.change(hour: evaluator.at_hour, min: evaluator.at_minute)
      end
    end
  end
end
