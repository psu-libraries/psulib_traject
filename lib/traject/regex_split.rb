# frozen_string_literal: true

# work-around for https://github.com/jruby/jruby/issues/4868
def regex_split(str, regex)
  str.split(regex).to_a
end

# work-around for https://github.com/jruby/jruby/issues/4868
def regex_to_extract_data_from_a_string(str, regex)
  str[regex]
end
