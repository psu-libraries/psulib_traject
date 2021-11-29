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

  factory :subject_empty_650 do
    f650 do
      { indicator2: '0' }
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

  factory :non_pst_subjects_650 do
    f650 do
      { indicator2: '0', x: 'A', y: 'B', z: 'C', t: 'ignore' }
    end

    f650 do
      { indicator2: '7', x: 'L', y: 'M', z: 'N' }
    end
  end

  factory :non_pst_subjects_non_650 do
    f600 do
      { indicator2: '0', a: 'A', b: 'B', c: 'C', d: 'D' }
    end

    f600 do
      { indicator2: '0', a: 'P', b: 'R', c: 'S', d: 'T' }
    end

    f610 do
      { indicator2: '0', a: 'E', b: 'F', c: 'G', d: 'H' }
    end

    f611 do
      { indicator2: '0', a: 'L', b: 'M', c: 'N', d: 'O' }
    end

    f630 do
      { indicator2: '0', a: '7', v: '8', x: '9', y: '10', z: '11' }
    end

    f647 do
      { indicator2: '0', a: '12', v: '13', x: '14', y: '15', z: '16' }
    end

    f651 do
      { indicator2: '0', a: '1', g: '2', v: '3', x: '4', y: '5', z: '6' }
    end

    f651 do
      { indicator2: '0', a: '1', g: '2', v: '3', x: '4', y: '5' }
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

  factory :repeated_headings do
    f650 do
      {
        indicator2: '0',
        a: 'Quilting'
      }
    end

    f650 do
      {
        indicator2: '0',
        a: 'Quilting',
        z: 'Pennsylvania'
      }
    end

    f650 do
      {
        indicator2: '0',
        a: 'Quilting',
        z: ['Pennsylvania', 'Cumberland County'],
        x: 'History',
        y: '18th century.'
      }
    end

    f650 do
      {
        indicator2: '0',
        a: 'Quilting',
        z: ['Pennsylvania', 'Cumberland County'],
        x: 'History',
        y: '19th century.'
      }
    end

    f650 do
      {
        indicator2: '0',
        a: 'Quilting',
        z: ['Pennsylvania', 'Cumberland County']
      }
    end

    f650 do
      {
        indicator2: '0',
        a: 'Quilting',
        z: ['Pennsylvania', 'Cumberland County'],
        x: 'History'
      }
    end
  end
end
