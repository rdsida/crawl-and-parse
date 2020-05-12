require_relative 'utils/string_converter'

# Generic helper functions not specific to any class
module Utils
  # Try real hard to convert random garbage into an integer. Returns nil if it
  # fails.
  def string_to_i(who_knows)
    StringConverter.new(who_knows).to_i
  end
end
