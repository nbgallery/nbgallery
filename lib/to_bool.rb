# Strings like 'yes' and 'true' and '1' are true; other stuff is false
class String
  def to_bool
    if to_i.zero?
      %w[yes y true on].any? {|s| s == downcase}
    else
      true # strings like "1"
    end
  end
end

# 0 is false; other number true
class Integer # rubocop: disable Lint/UnifiedInteger
  def to_bool
    nonzero?
  end
end

# nil is false
class NilClass
  def to_bool
    false
  end
end

# true is true
class TrueClass
  def to_bool
    true
  end
end

# false is false
class FalseClass
  def to_bool
    false
  end
end
