require 'humanize'

# Generic helper functions not specific to any class
module Utils
  # Try real hard to convert random garbage into an integer. Returns nil if it
  # fails.
  def string_to_i(who_knows)
    if who_knows.class == Integer
      who_knows
    elsif who_knows.class == String
      handle_string_number(who_knows)
    end
  end

  # Called once we know the input is a string.
  def handle_string_number(string)
    string = clean_number_string(string)

    # 'eleven'
    if h_numbers[string]
      h_numbers[string]

    # '100k'
    elsif string =~ /^([0-9]+)\s?k/
      Regexp.last_match(1).to_i * 1000

    # '100000'
    elsif string =~ /([0-9]+)/
      Regexp.last_match(1).to_i
    else
      handle_special_cases(string)
    end
  end

  def clean_number_string(dirty)
    [',', '-', '‡', '~'].each do |bad_char|
      dirty.delete! bad_char
    end

    dirty
      .strip
      .squeeze(' ')
      .delete_prefix('Appx. ')
      .downcase
  end

  def handle_special_cases(string)
    if string == '--'
      0

    elsif string.include?('in progress')
      nil

    # I don't know why we return an empty string here instead of nil like the
    # other cases. Leaving it for now.
    elsif string.include?('App')
      ''

    else
      warn "Invalid number string: #{string}"
    end
  end

  # Hash: Keys are english numbers, values are integers. I.E.
  # { 'one' => 1, 'two' => 2, (...) }
  def h_numbers
    @h_numbers ||= build_h_numbers
  end

  def build_h_numbers
    numbers = {}
    1000.times { |i| numbers[i.humanize.gsub('-', ' ')] = i }

    numbers
  end
end
