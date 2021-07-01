# frozen_string_literal: true

MarcBot.define do
  # Defines a suitably randomized MARC record that we can add things to selectively
  factory :record do
    f001 { Faker::Number.leading_zero_number(digits: 10) }
    f003 { 'SIRSI' }
  end
end
