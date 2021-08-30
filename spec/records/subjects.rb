# frozen_string_literal: true

MarcBot.define do
  factory :subject_facet do
    f610 do
      { indicator2: '5', a: 'Include' }
    end

    f600 do
      { indicator2: '0', a: 'John.', t: 'Title.', v: 'split genre', d: '2015', 2 => 'special' }
    end

    f630 do
      { indicator2: '0', x: 'Fiction', y: '1492', z: "don't ignore", t: 'TITLE.' }
    end
  end

  factory :subject_topic_facet do
    f600 do
      { indicator2: '0', a: 'John.', x: 'Join', t: 'Title', d: '2015.' }
    end

    f650 do
      { indicator2: '0', x: 'Fiction', y: '1492', v: 'split genre' }
    end
  end

  factory :non_pst_subjects do
    f650 do
      { indicator2: '0', x: 'A', y: 'B', z: 'C', t: 'ignore' }
    end

    f650 do
      { indicator2: '7', x: 'L', y: 'M', z: 'N' }
    end
  end

  factory :pst_subjects do
    f650 do
      { indicator2: '0', x: 'A', y: 'B', z: 'C', t: 'ignore' }
    end

    f650 do
      { indicator2: '7', x: 'L', y: 'M', z: 'N', 2 => 'Pst' }
    end
  end
end
