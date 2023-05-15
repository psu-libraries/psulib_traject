# frozen_string_literal: true

MarcBot.define do
  factory :series_title_830_only do
    f830 do
      {
        indicator2: '0',
        a: 'Series Title With 830',
        v: '4'
      }
    end
  end

  factory :series_title_830_and_490_no_append_409 do
    f830 do
      {
        indicator2: '0',
        a: 'Series Title With 830',
        v: '4'
      }
    end
    f490 do
      {
        indicator1: '1',
        a: '490 does not display',
        v: '4'
      }
    end
  end

  factory :series_title_830_and_490 do
    f830 do
      {
        indicator2: '0',
        a: 'Series Title With 830',
        v: '4'
      }
    end
    f490 do
      {
        indicator1: '0',
        a: 'Series Title With 490',
        v: '4'
      }
    end
  end

  factory :series_title_830_and_440 do
    f830 do
      {
        indicator2: '0',
        a: 'does not display 830',
        v: '4'
      }
    end
    f440 do
      {
        a: 'Series Title With 440',
        v: '1'
      }
    end
  end

  factory :series_title_490_only do
    f490 do
      {
        indicator1: '0',
        a: 'Series Title With 490',
        v: '4'
      }
    end
  end

  factory :series_title_490_and_440 do
    f490 do
      {
        indicator1: ' ',
        a: 'does not display 490',
        v: '4'
      }
    end
    f440 do
      {
        a: 'Series Title With 440',
        v: '1'
      }
    end
  end

  factory :series_title_440_only do
    f440 do
      {
        a: 'Series Title With 440',
        v: '1'
      }
    end
  end
end
